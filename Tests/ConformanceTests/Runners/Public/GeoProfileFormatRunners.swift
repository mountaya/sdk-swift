import Foundation
import GateSupport
import MountayaClient
import MountayaGeo

extension PublicRunners {
  /// profileSlopeRamp answers the colour a slope of the case's `degrees` paints, and its steepness
  /// class, or null. The two ramps, the overlay's slug and the class thresholds are held to the
  /// ones Geo publishes.
  static let profileSlopeRamp = Runner(id: "geo.profile.slope-ramp", table: .public) {
    fixture, fixtureCase in
    func stops(_ ramp: [SlopeRampStop]) -> OrderedJSON {
      .array(
        ramp.map {
          .object([
            OrderedJSON.Member(key: "color", value: .string($0.color)),
            OrderedJSON.Member(key: "degrees", value: .number($0.degrees)),
          ])
        })
    }
    try fixture.holdConstants(
      [:],
      values: [
        "ascentRampStops": stops(ascentSlopeRamp),
        "descentRampStops": stops(descentSlopeRamp),
        "steepnessOverlaySlug": .string(steepnessOverlaySlug),
        "steepnessThresholds": .array(SteepnessClass.allCases.map { .number($0.fromDegrees) }),
      ]
    )
    let degrees = try fixtureCase.input.number(at: "degrees")
    return .value(
      .object([
        OrderedJSON.Member(key: "color", value: .string(slopeRampColor(degrees))),
        OrderedJSON.Member(
          key: "steepness", value: GeoProfileFixtures.text(classifySteepness(degrees)?.id)),
      ]))
  }

  /// profileUnitFormatting answers the case's `value` as a reader of its `units` is shown it, in
  /// the formatter its `measure` names. The lengths a unit is defined by are held to the
  /// conversions, and each preference's vocabulary to the values the wire's preference names.
  ///
  /// The unit patterns, their widths, the minimum grouping digits and the rounding mode are held to
  /// what the published formatters write, language by language: each pattern read off a
  /// measurement whose number every language writes alike, the widths to the ones Geo's table says
  /// it holds, the narrow degree sign, hour and minute and the short others, the grouping off the
  /// elevations 1531 and 15,310, and the rounding off the halves it writes.
  static let profileUnitFormatting = Runner(id: "geo.profile.unit-formatting", table: .public) {
    fixture, fixtureCase in
    func words(_ words: String...) -> OrderedJSON { .array(words.map { .string($0) }) }
    let languages = (fixture.constants?["unitPatterns"]?.members ?? []).map(\.key)
    let patterns = try languages.map { language in
      OrderedJSON.Member(key: language, value: try writtenPatterns(language))
    }
    let units = Set(
      patterns.flatMap { $0.value.members?.map(\.key) ?? [] }
    ).sorted()
    try fixture.holdConstants(
      [
        "centimetersPerInch": convertLength(1, from: .inch, to: .centimeter),
        "kilometersPerMile": convertLength(1, from: .mile, to: .kilometer),
        "metersPerFoot": convertLength(1, from: .foot, to: .meter),
        "metersPerMile": convertLength(1, from: .mile, to: .meter),
      ],
      values: [
        "minimumGroupingDigits": .object(
          try languages.map { language in
            OrderedJSON.Member(key: language, value: .number(Double(try groupingDigits(language))))
          }),
        "roundingMode": .string(roundingMode()),
        "unitLengths": words(
          RestSchema.UnitLength.metric.rawValue,
          RestSchema.UnitLength.imperial.rawValue),
        "unitPaces": words(
          RestSchema.UnitPace.perTime.rawValue,
          RestSchema.UnitPace.perDistance.rawValue),
        "unitPatternWidths": .object(
          units.map {
            OrderedJSON.Member(
              key: $0, value: .string(narrowUnits.contains($0) ? "narrow" : "short"))
          }),
        "unitPatterns": .object(patterns),
        "unitSlopes": words(
          RestSchema.UnitSlope.degrees.rawValue,
          RestSchema.UnitSlope.percentage.rawValue),
        "unitTemperatures": words(
          RestSchema.UnitTemperature.celsius.rawValue,
          RestSchema.UnitTemperature.fahrenheit.rawValue),
      ]
    )
    let input = fixtureCase.input
    let preferences = try GeoProfileFixtures.units(input["units"])
    let value = try input.optionalNumber(at: "value")
    let measure = try input.string(at: "measure")
    let text: String
    switch measure {
    case "distance": text = formatDistance(value, units: preferences)
    case "elevation": text = formatElevation(value, units: preferences)
    case "slope": text = formatSlope(value, units: preferences)
    case "speed": text = formatSpeed(value, units: preferences)
    case "temperature": text = formatTemperature(value, units: preferences)
    case "duration": text = formatDuration(value, units: preferences)
    case "humidity": text = formatHumidity(value, units: preferences)
    case "snowfall": text = formatSnowfall(value, units: preferences)
    default:
      throw FixtureError(description: "no measure is called `\(measure)`")
    }
    return .value(.string(text))
  }

  /// narrowUnits is the units whose patterns are CLDR's narrow ones, as Geo's table says of them:
  /// the degree sign and a duration's hours and minutes. Every other is the short one. The table
  /// holds the patterns alone, so their widths are held to what it says of them.
  private static let narrowUnits: Set<String> = ["degree", "hour", "minute"]

  /// writtenPatterns is the pattern each unit is written in for a reader of `language`, by its
  /// ECMA-402 unit id, read off what the published formatters write: a measurement of 5 of the
  /// unit, a duration of 2 hours and one of 5 minutes, and a pace of 5 minutes, each number written
  /// in place of `{0}`.
  private static func writtenPatterns(_ language: String) throws -> OrderedJSON {
    func units(
      length: RestSchema.UnitLength = .metric, pace: RestSchema.UnitPace = .perTime,
      slope: RestSchema.UnitSlope = .degrees, temperature: RestSchema.UnitTemperature = .celsius
    ) -> UnitPreferences {
      UnitPreferences(
        language: language, length: length, pace: pace, slope: slope, temperature: temperature)
    }
    func pattern(_ written: String, number: String) throws -> OrderedJSON {
      let parts = written.components(separatedBy: number)
      guard parts.count == 2 else {
        throw FixtureError(
          description: "`\(written)` does not hold `\(number)` once, in `\(language)`")
      }
      return .string(parts.joined(separator: "{0}"))
    }
    let metersPerFoot = convertLength(1, from: .foot, to: .meter)
    let metersPerMile = convertLength(1, from: .mile, to: .meter)
    let kmhPerMph = convertSpeed(1, from: .milePerHour, to: .kilometerPerHour)
    let fahrenheit = convertTemperature(5, from: .fahrenheit, to: .celsius)
    let centimetersPerInch = convertLength(1, from: .inch, to: .centimeter)
    return .object([
      OrderedJSON.Member(
        key: "celsius", value: try pattern(formatTemperature(5, units: units()), number: "5")),
      OrderedJSON.Member(
        key: "centimeter", value: try pattern(formatSnowfall(5, units: units()), number: "5")),
      OrderedJSON.Member(
        key: "degree", value: try pattern(formatSlope(5, units: units()), number: "5")),
      OrderedJSON.Member(
        key: "fahrenheit",
        value: try pattern(
          formatTemperature(fahrenheit, units: units(temperature: .fahrenheit)), number: "5")
      ),
      OrderedJSON.Member(
        key: "foot",
        value: try pattern(
          formatElevation(5 * metersPerFoot, units: units(length: .imperial)), number: "5")
      ),
      OrderedJSON.Member(
        key: "hour", value: try pattern(formatDuration(7200, units: units()), number: "2")),
      OrderedJSON.Member(
        key: "inch",
        value: try pattern(
          formatSnowfall(5 * centimetersPerInch, units: units(length: .imperial)), number: "5")),
      OrderedJSON.Member(
        key: "kilometer", value: try pattern(formatDistance(5000, units: units()), number: "5")),
      OrderedJSON.Member(
        key: "kilometer-per-hour", value: try pattern(formatSpeed(5, units: units()), number: "5")),
      OrderedJSON.Member(
        key: "meter", value: try pattern(formatElevation(5, units: units()), number: "5")),
      OrderedJSON.Member(
        key: "mile",
        value: try pattern(
          formatDistance(5 * metersPerMile, units: units(length: .imperial)), number: "5")
      ),
      OrderedJSON.Member(
        key: "mile-per-hour",
        value: try pattern(formatSpeed(5 * kmhPerMph, units: units(length: .imperial)), number: "5")
      ),
      OrderedJSON.Member(
        key: "minute", value: try pattern(formatDuration(300, units: units()), number: "5")),
      OrderedJSON.Member(
        key: "minute-per-kilometer",
        value: try pattern(formatSpeed(12, units: units(pace: .perDistance)), number: "5:00")),
      OrderedJSON.Member(
        key: "minute-per-mile",
        value: try pattern(
          formatSpeed(12 * kmhPerMph, units: units(length: .imperial, pace: .perDistance)),
          number: "5:00")),
      OrderedJSON.Member(
        key: "percent",
        value: try pattern(
          formatSlope(
            convertSlope(5, from: .percentage, to: .degrees), units: units(slope: .percentage)),
          number: "5")),
    ])
  }

  /// groupingDigits is the fewest digits the first group of a number `language` groups holds, as
  /// the elevations it writes show: 1 where it groups 1531, 2 where it groups 15,310 and not 1531.
  private static func groupingDigits(_ language: String) throws -> Int {
    let units = UnitPreferences(language: language)
    let meter = try writtenPatterns(language)["meter"]?.stringValue ?? ""
    func grouped(_ meters: Double) -> Bool {
      formatElevation(meters, units: units)
        != meter.replacingOccurrences(of: "{0}", with: String(Int(meters)))
    }
    if grouped(1531) { return 1 }
    if grouped(15310) { return 2 }
    throw FixtureError(description: "`\(language)` groups neither 1531 nor 15,310")
  }

  /// roundingMode is the rounding the formatters apply, named as the contract names it: a half
  /// rounded away from zero both ways, on the decimal value a reader writes, so 2.5° is `3°`,
  /// -2.5° is `-3°` and 850 m is `0.9 km`, though 0.85 is held in binary as a little less.
  private static func roundingMode() -> String {
    let english = UnitPreferences(language: "en")
    let halves = [
      formatSlope(2.5, units: english), formatSlope(-2.5, units: english),
      formatDistance(850, units: english),
    ]
    return halves == ["3°", "-3°", "0.9 km"]
      ? "half-away-from-zero" : "none the contract names: \(halves)"
  }

  /// profileSplitDuration answers the hours and minutes the case's `seconds` split into, or null.
  /// The fixture's minute and hour are held to the duration conversions.
  static let profileSplitDuration = Runner(id: "geo.profile.split-duration", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants([
      "minutesPerHour": convertDuration(1, from: .hour, to: .minute),
      "secondsPerMinute": convertDuration(1, from: .minute, to: .second),
    ])
    guard let split = splitDuration(try fixtureCase.input.optionalNumber(at: "seconds")) else {
      return .value(.null)
    }
    return .value(
      .object([
        OrderedJSON.Member(key: "hours", value: .number(Double(split.hours))),
        OrderedJSON.Member(key: "minutes", value: .number(Double(split.minutes))),
      ]))
  }

  /// profilePaceClock answers the one of the four readings of a pace clock the case's `operation`
  /// names: `format`, `parse`, `toClockNumber` or `fromClockNumber`.
  static let profilePaceClock = Runner(id: "geo.profile.pace-clock", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    switch try input.string(at: "operation") {
    case "format":
      return .value(.string(formatPaceClock(try input.optionalNumber(at: "minutes"))))
    case "parse":
      return .value(GeoProfileFixtures.number(parsePaceClock(try input.string(at: "text"))))
    case "toClockNumber":
      return .value(
        GeoProfileFixtures.number(paceMinutesToClockNumber(try input.optionalNumber(at: "minutes")))
      )
    case "fromClockNumber":
      return .value(
        GeoProfileFixtures.number(paceClockNumberToMinutes(try input.optionalNumber(at: "value"))))
    case let other:
      throw FixtureError(
        description:
          "`operation` is `format`, `parse`, `toClockNumber` or `fromClockNumber`, not `\(other)`")
    }
  }

  /// profileWaypointSummary answers what the place the case's `details` describe says about
  /// itself, its headline, and whether it declares nothing. The place is built as the REST API's
  /// waypoint: the fixture writes a place's details as `geo.data.itinerary-waypoints` answers them,
  /// a timing's `cutoffAt` and `stopDuration` and a contact's `openingHours`, and the rule takes
  /// REST's waypoint, `cutoff_at`, `stop_duration` and `opening_hours`, so the runner reads them at
  /// its own edge, as the fixture's description says an SDK does. The words are the
  /// fixture's templates, each holding one placeholder, and a case's `cutoffMoment` is what the
  /// caller's formatter answers for the place's own cut-off; a case that states none has a caller
  /// with no formatter.
  static let profileWaypointSummary = Runner(
    id: "geo.profile.waypoint-summary", table: .public
  ) { fixture, fixtureCase in
    guard let copy = fixture.copy, let summary = copy["summary"], summary.members != nil else {
      throw FixtureError(description: "the copy has no `summary`")
    }
    let words = WaypointSummaryWords(
      amenities: try copy.string(at: "amenities"),
      openingHours: try clause(try summary.string(at: "openingHours")),
      cutoffAt: try clause(try summary.string(at: "cutoffAt")),
      stop: try clause(try summary.string(at: "stop"))
    )
    let units = try GeoProfileFixtures.units(fixture.document["units"])
    let input = fixtureCase.input
    guard let details = input["details"], details.members != nil else {
      throw FixtureError(description: "the case has no `details`")
    }
    var amenities: [String] = []
    if details["amenities"] != nil {
      for amenity in try details.array(at: "amenities") {
        guard let word = amenity.stringValue else {
          throw FixtureError(description: "a service is no string")
        }
        amenities.append(word)
      }
    }
    var cutoffAt: Date?
    var timing: RestSchema.WaypointTiming?
    if let written = details["timing"], written.members != nil {
      if let instant = try written.optionalString(at: "cutoffAt") {
        cutoffAt = try GeoProfileFixtures.instant(instant)
      }
      let stop = try written.optionalInteger(at: "stopDuration")
      timing = RestSchema.WaypointTiming { [cutoffAt] built in
        built.cutoff_at = .some(cutoffAt)
        built.stop_duration = .some(stop)
      }
    }
    var contact: RestSchema.WaypointContact?
    if let written = details["contact"], written.members != nil {
      let phone = try written.optionalString(at: "phone")
      let hours = try written.optionalString(at: "openingHours")
      contact = RestSchema.WaypointContact { built in
        built.phone = .some(phone)
        built.opening_hours = .some(hours)
      }
    }
    let place = GeoProfileFixtures.waypoint(
      amenities: amenities, description: try details.optionalString(at: "description"),
      timing: timing, contact: contact)
    var handedAnother = false
    var formatCutoffAt: ((Date) -> String)?
    if let moment = try input.optionalString(at: "cutoffMoment") {
      formatCutoffAt = { instant in
        if instant != cutoffAt { handedAnother = true }
        return moment
      }
    }
    let headline = waypointHeadline(
      place, words: words, units: units, formatCutoffAt: formatCutoffAt)
    let line = waypointSummary(place, words: words, units: units, formatCutoffAt: formatCutoffAt)
    guard !handedAnother else {
      throw FixtureError(description: "the formatter is handed an instant other than the cut-off")
    }
    return .value(
      .object([
        OrderedJSON.Member(key: "declaresNothing", value: .bool(waypointDeclaresNothing(place))),
        OrderedJSON.Member(key: "headline", value: GeoProfileFixtures.text(headline)),
        OrderedJSON.Member(key: "summary", value: GeoProfileFixtures.text(line)),
      ]))
  }

  /// profileWebAddress answers whether the case's `address`, as written, is one the API accepts,
  /// and whether a card links it. A linked address is linked as it reads past the white space at
  /// its ends, the set ECMAScript's trim removes (`trimWhiteSpace(_:)`), and by no other spelling,
  /// which the runner holds too, scalar for scalar.
  static let profileWebAddress = Runner(id: "geo.profile.web-address", table: .public) {
    _, fixtureCase in
    let address = try fixtureCase.input.string(at: "address")
    let linked = linkedWebAddress(address)
    if let linked,
      !linked.unicodeScalars.elementsEqual(trimWhiteSpace(address).unicodeScalars)
    {
      throw FixtureError(description: "the address is linked as `\(linked)`")
    }
    return .value(
      .object([
        OrderedJSON.Member(key: "accepted", value: .bool(isWebAddress(address))),
        OrderedJSON.Member(key: "linked", value: .bool(linked != nil)),
      ]))
  }

  /// profileCharacteristics answers the summary the case's `segments` and `waypoints` fold into,
  /// each built as the REST API's with the wire's fields the fixture writes. The rank table is held
  /// to the rank the rule gives every grade the wire names.
  static let profileCharacteristics = Runner(
    id: "geo.profile.characteristics", table: .public
  ) { fixture, fixtureCase in
    let grades: [RestSchema.TrailDifficultyType] = [
      .unknown, .hiking, .mountainHiking,
      .demandingMountainHiking, .alpineHiking,
      .demandingAlpineHiking, .difficultAlpineHiking,
      .mtb0, .mtb1, .mtb2,
      .mtb3, .mtb4, .mtb5,
      .mtb6,
    ]
    try fixture.holdConstants(
      [:],
      values: [
        "trailDifficultyRank": .object(
          grades.map {
            OrderedJSON.Member(
              key: $0.rawValue,
              value: GeoProfileFixtures.number(trailDifficultyRank($0).map(Double.init)))
          })
      ]
    )
    let input = fixtureCase.input
    var segments: [RestSchema.ItinerarySegment] = []
    for fields in try input.array(at: "segments") {
      segments.append(try GeoProfileFixtures.segment(fields))
    }
    var waypoints: [RestSchema.ItineraryWaypoint] = []
    for written in try input.array(at: "waypoints") {
      waypoints.append(try GeoProfileFixtures.timedWaypoint(written))
    }
    return .value(
      GeoProfileFixtures.characteristics(
        MountayaGeo.profileCharacteristics(segments, waypoints: waypoints)))
  }

  /// profileCommittedPace answers the committed pace over the case's `segments`, each built as the
  /// REST API's segment with its `distance` and `duration` as the fixture writes them, a number
  /// JSON cannot carry included, and a placeholder for every other member.
  static let profileCommittedPace = Runner(id: "geo.profile.committed-pace", table: .public) {
    _, fixtureCase in
    var segments: [RestSchema.ItinerarySegment] = []
    for fields in try fixtureCase.input.array(at: "segments") {
      segments.append(try GeoProfileFixtures.segment(fields))
    }
    return .value(GeoProfileFixtures.number(committedPace(segments)))
  }

  /// The clause a template reads, its one placeholder, `{` then lower-case letters then `}`, taken
  /// by the value. A template that holds no placeholder, or more than one, fails the case.
  private static func clause(_ template: String) throws(FixtureError)
    -> @Sendable (String) -> String
  {
    let scalars = Array(template.unicodeScalars)
    guard scalars.filter({ $0 == "{" }).count == 1, let open = scalars.firstIndex(of: "{"),
      let close = scalars[open...].firstIndex(of: "}"), close > open + 1,
      scalars[(open + 1)..<close].allSatisfy({ ("a"..."z").contains($0) })
    else {
      throw FixtureError(description: "the template `\(template)` does not hold one placeholder")
    }
    let head = String(String.UnicodeScalarView(scalars[..<open]))
    let tail = String(String.UnicodeScalarView(scalars[(close + 1)...]))
    return { value in head + value + tail }
  }
}
