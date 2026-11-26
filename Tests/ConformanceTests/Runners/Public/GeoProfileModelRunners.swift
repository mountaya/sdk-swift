import Foundation
import GateSupport
import MountayaClient
import MountayaGeo

extension PublicRunners {
  /// profileSegmentRows answers the case's `segments` as table rows over its `series`. Each segment
  /// is a leg holding its identity and geometry, and its stated `metrics` are stated for it by its
  /// id, the leg's own figures left out, which is the same reading.
  static let profileSegmentRows = Runner(id: "geo.profile.segment-rows", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    var legs: [ItineraryLeg] = []
    var stated: [String: ItinerarySegmentRowMetrics] = [:]
    for segment in try input.array(at: "segments") {
      let id = try segment.string(at: "id")
      var geometry: GeoJSONGeometry?
      if let written = segment["geojson"], !written.isNull {
        geometry = try GeoFixtures.geometry(written)
      }
      legs.append(
        ItineraryLeg(
          id: id, memberIds: try ProfileModelJSON.optionalTexts(segment["memberIds"]),
          name: try segment.optionalString(at: "name") ?? "",
          color: try segment.optionalString(at: "color"),
          geometry: geometry))
      if let metrics = segment["metrics"], !metrics.isNull {
        stated[id] = try ProfileModelJSON.segmentMetrics(metrics)
      }
    }
    let rows = itinerarySegmentRows(
      try GeoProfileFixtures.series(input["series"]), legs: legs, stated: stated)
    return .value(.array(rows.map(ProfileModelJSON.segmentRowValue)))
  }

  /// profileWaypointRows answers the case's `waypoints` as waypoint rows over its `geometry` and
  /// `series`, each placed at its `distance` or its `lngLat`, with its stated `metrics`.
  static let profileWaypointRows = Runner(id: "geo.profile.waypoint-rows", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    var places: [ProfilePlace] = []
    for waypoint in try input.array(at: "waypoints") {
      places.append(try ProfileModelJSON.place(waypoint))
    }
    var geometry: GeoJSONGeometry?
    if let written = input["geometry"], !written.isNull {
      geometry = try GeoFixtures.geometry(written)
    }
    let rows = itineraryWaypointRows(
      try GeoProfileFixtures.series(input["series"]), geometry: geometry, places: places)
    return .value(
      .array(
        rows.map { row in
          var members: [OrderedJSON.Member] = [
            OrderedJSON.Member(key: "from", value: .number(row.from)),
            OrderedJSON.Member(key: "id", value: .string(row.place.id)),
            OrderedJSON.Member(key: "index", value: .number(Double(row.index))),
            OrderedJSON.Member(key: "key", value: .string(row.key)),
            OrderedJSON.Member(
              key: "metrics", value: ProfileModelJSON.waypointMetricsValue(row.metrics)),
            OrderedJSON.Member(key: "to", value: .number(row.to)),
          ]
          if let name = row.place.name {
            members.append(OrderedJSON.Member(key: "name", value: .string(name)))
          }
          if let glyph = row.place.glyph {
            members.append(OrderedJSON.Member(key: "glyph", value: .string(glyph.rawValue)))
          }
          return .object(members)
        }))
  }

  /// profileWaypointCard answers the card a place of the case's `details` states, for its `units`,
  /// a cut-off written as its `cutoffMoment` where it states one. Its words are read from a scope
  /// whose every word of the `amenities` and `waypointCard` sections is its own path, so a label
  /// that reads as a path is that word, and a service's name that does not is its own value.
  static let profileWaypointCard = Runner(id: "geo.profile.waypoint-card", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    let card = waypointCard(
      try ProfileModelJSON.details(input["details"]), scope: ProfileModelJSON.referencedScope,
      units: try ProfileModelJSON.units(input["units"]),
      formatCutoffAt: try ProfileModelJSON.formatter(input, at: "cutoffMoment"))
    func line(_ line: WaypointCardFacts.Line) -> OrderedJSON {
      var members = [
        OrderedJSON.Member(key: "label", value: ProfileModelJSON.word(line.label)),
        OrderedJSON.Member(key: "value", value: .string(line.value)),
      ]
      if let href = line.href {
        members.append(OrderedJSON.Member(key: "href", value: .string(href)))
      }
      if line.isExternal { members.append(OrderedJSON.Member(key: "external", value: .bool(true))) }
      return .object(members)
    }
    return .value(
      ProfileJSON.object([
        "contact": .array(card.contact.map(line)),
        "fields": .array(card.fields.map(ProfileModelJSON.fieldValue)),
        "services": .array(
          card.services.map {
            ProfileJSON.object([
              "amenity": .string($0.amenity.rawValue), "name": ProfileModelJSON.word($0.name),
            ])
          }),
        "timing": .array(card.timing.map(line)),
      ]))
  }

  /// profileWaypointPropertyValue answers how the case's `property` reads for its `units`, an
  /// instant written as its `instantMoment` where it states one, and the address it links to.
  static let profileWaypointPropertyValue = Runner(
    id: "geo.profile.waypoint-property-value", table: .public
  ) { _, fixtureCase in
    let input = fixtureCase.input
    let property = try ProfileModelJSON.property(input["property"])
    let text = waypointPropertyValue(
      property, units: try ProfileModelJSON.units(input["units"]),
      formatInstant: try ProfileModelJSON.formatter(input, at: "instantMoment"))
    return .value(
      ProfileJSON.object([
        "href": GeoProfileFixtures.text(waypointPropertyLink(property)), "text": .string(text),
      ]))
  }

  /// profileLineBetween answers the stretch of the case's `series` between its `from` and its `to`
  /// as a GeoJSON line, or null.
  static let profileLineBetween = Runner(id: "geo.profile.line-between", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    let line = lineBetween(
      try GeoProfileFixtures.series(input["series"]).points, from: try input.number(at: "from"),
      to: try input.number(at: "to"))
    return .value(line.map(GeoFixtures.written) ?? .null)
  }

  /// formatAltitudeRange answers how a band from the case's `min` to its `max` is written for its
  /// `units`, after holding the fixture's `rangePatterns` to the ones the published formatter writes
  /// in each of its languages (`writtenRangePatterns(_:)`).
  static let formatAltitudeRange = Runner(id: "geo.format.altitude-range", table: .public) {
    fixture, fixtureCase in
    let languages = (fixture.constants?["rangePatterns"]?.members ?? []).map(\.key)
    try fixture.holdConstants([:], values: ["rangePatterns": try writtenRangePatterns(languages)])
    let input = fixtureCase.input
    let text = MountayaGeo.formatAltitudeRange(
      min: try input.optionalNumber(at: "min"), max: try input.optionalNumber(at: "max"),
      units: try ProfileModelJSON.units(input["units"]))
    return .value(.string(text))
  }

  /// writtenRangePatterns reads each language's range and approximately patterns back off what
  /// the published formatter writes, a plain import reaching no table: a band from 1 to 2 meters and
  /// one of 5, each stripped of the language's elevation unit as `formatElevation(_:units:)` writes
  /// it, the numbers then put back as `{0}` and `{1}`.
  private static func writtenRangePatterns(_ languages: [String]) throws(FixtureError)
    -> OrderedJSON
  {
    var written: [OrderedJSON.Member] = []
    for language in languages {
      let units = UnitPreferences(language: language, length: .metric)
      let unit = formatElevation(7, units: units).components(separatedBy: "7")
      guard unit.count == 2 else {
        throw FixtureError(description: "the elevation unit of `\(language)` holds no one number")
      }
      func inner(_ text: String) throws(FixtureError) -> String {
        guard text.hasPrefix(unit[0]), text.hasSuffix(unit[1]) else {
          throw FixtureError(description: "`\(text)` is not written in its unit, in `\(language)`")
        }
        return String(text.dropFirst(unit[0].count).dropLast(unit[1].count))
      }
      let range = try inner(MountayaGeo.formatAltitudeRange(min: 1, max: 2, units: units))
        .replacingOccurrences(of: "1", with: "{0}").replacingOccurrences(of: "2", with: "{1}")
      let approximately = try inner(MountayaGeo.formatAltitudeRange(min: 5, max: 5, units: units))
        .replacingOccurrences(of: "5", with: "{0}")
      written.append(
        OrderedJSON.Member(
          key: language,
          value: .object([
            OrderedJSON.Member(key: "approximately", value: .string(approximately)),
            OrderedJSON.Member(key: "range", value: .string(range)),
          ])))
    }
    return .object(written)
  }

  /// profileClassificationColors answers the colour a stretch of the case's `kind`, `surface` or
  /// `way-type`, and `value` paints in. Both tables and the unclassified grey are held to the
  /// published ones.
  static let profileClassificationColors = Runner(
    id: "geo.profile.classification-colors", table: .public
  ) { fixture, fixtureCase in
    try fixture.holdConstants(
      [:],
      values: [
        "surfaces": .object(
          surfaceColors.map {
            OrderedJSON.Member(key: $0.key.rawValue, value: .string($0.value.hex))
          }),
        "unclassified": .string(unclassifiedColor.hex),
        "wayTypes": .object(
          wayTypeColors.map {
            OrderedJSON.Member(key: $0.key.rawValue, value: .string($0.value.hex))
          }),
      ])
    let input = fixtureCase.input
    let value = try input.string(at: "value")
    switch try input.string(at: "kind") {
    case "surface":
      return .value(.string(surfaceColor(RestSchema.SurfaceType(rawValue: value)).hex))
    case "way-type":
      return .value(.string(wayTypeColor(RestSchema.WayType(rawValue: value)).hex))
    case let kind:
      throw FixtureError(description: "`\(kind)` is no classification")
    }
  }
}

/// ProfileModelJSON reads the values the profile's element model fixtures write, and writes answers
/// in their shapes.
enum ProfileModelJSON {
  /// texts reads a list of texts.
  static func texts(_ value: OrderedJSON) throws(FixtureError) -> [String] {
    guard let elements = value.elements else {
      throw FixtureError(description: "a list of texts is not an array")
    }
    var texts: [String] = []
    for element in elements {
      guard let text = element.stringValue else {
        throw FixtureError(description: "a list of texts holds a value that is no text")
      }
      texts.append(text)
    }
    return texts
  }

  /// optionalTexts reads a list of texts a case may leave out, empty where it does.
  static func optionalTexts(_ value: OrderedJSON?) throws(FixtureError) -> [String] {
    guard let value, !value.isNull else { return [] }
    return try texts(value)
  }

  /// segmentMetrics reads a segment's stated `metrics`, any of its ten figures.
  static func segmentMetrics(_ value: OrderedJSON) throws(FixtureError)
    -> ItinerarySegmentRowMetrics
  {
    ItinerarySegmentRowMetrics(
      distance: try value.optionalNumber(at: "distance"),
      sectionDistance: try value.optionalNumber(at: "sectionDistance"),
      ascent: try value.optionalNumber(at: "ascent"),
      descent: try value.optionalNumber(at: "descent"),
      sectionAscent: try value.optionalNumber(at: "sectionAscent"),
      sectionDescent: try value.optionalNumber(at: "sectionDescent"),
      altitudeMin: try value.optionalNumber(at: "altitudeMin"),
      altitudeMax: try value.optionalNumber(at: "altitudeMax"),
      duration: try value.optionalNumber(at: "duration"),
      difficulty: try value.optionalString(at: "difficulty").map {
        RestSchema.TrailDifficultyType(rawValue: $0)
      }
    )
  }

  /// segmentMetricsValue writes a row's ten figures, each null where it has none.
  static func segmentMetricsValue(_ metrics: ItinerarySegmentRowMetrics) -> OrderedJSON {
    ProfileJSON.object([
      "altitudeMax": GeoProfileFixtures.number(metrics.altitudeMax),
      "altitudeMin": GeoProfileFixtures.number(metrics.altitudeMin),
      "ascent": GeoProfileFixtures.number(metrics.ascent),
      "descent": GeoProfileFixtures.number(metrics.descent),
      "difficulty": GeoProfileFixtures.text(metrics.difficulty?.rawValue),
      "distance": GeoProfileFixtures.number(metrics.distance),
      "duration": GeoProfileFixtures.number(metrics.duration),
      "sectionAscent": GeoProfileFixtures.number(metrics.sectionAscent),
      "sectionDescent": GeoProfileFixtures.number(metrics.sectionDescent),
      "sectionDistance": GeoProfileFixtures.number(metrics.sectionDistance),
    ])
  }

  /// segmentRowValue writes a segment row, its colour and members only where it has them.
  static func segmentRowValue(_ row: ItinerarySegmentRow) -> OrderedJSON {
    var members = [
      OrderedJSON.Member(key: "from", value: .number(row.from)),
      OrderedJSON.Member(key: "id", value: .string(row.id)),
      OrderedJSON.Member(key: "index", value: .number(Double(row.index))),
      OrderedJSON.Member(key: "key", value: .string(row.key)),
      OrderedJSON.Member(key: "metrics", value: segmentMetricsValue(row.metrics)),
      OrderedJSON.Member(key: "name", value: .string(row.name)),
      OrderedJSON.Member(key: "to", value: .number(row.to)),
    ]
    if let color = row.color {
      members.append(OrderedJSON.Member(key: "color", value: .string(color)))
    }
    if !row.memberIds.isEmpty {
      members.append(OrderedJSON.Member(key: "memberIds", value: GeoFixtures.texts(row.memberIds)))
    }
    return .object(members)
  }

  /// segmentRow reads a segment row as `geo.profile.segment-rows` writes one.
  static func segmentRow(_ value: OrderedJSON?) throws(FixtureError) -> ItinerarySegmentRow {
    guard let value, value.members != nil else {
      throw FixtureError(description: "the case's `row` is not an object")
    }
    return ItinerarySegmentRow(
      key: try value.string(at: "key"), id: try value.string(at: "id"),
      memberIds: try optionalTexts(value["memberIds"]),
      name: try value.optionalString(at: "name") ?? "",
      color: try value.optionalString(at: "color"),
      index: try value.integer(at: "index"), from: try value.number(at: "from"),
      to: try value.number(at: "to"),
      metrics: try segmentMetrics(value["metrics"] ?? .object([])))
  }

  /// place reads a waypoint a profile fixture writes: its id, placed at its `distance` or its
  /// `lngLat`, with its name, glyph, flags, stated metrics and details where it states them.
  static func place(_ value: OrderedJSON) throws(FixtureError) -> ProfilePlace {
    let id = try value.string(at: "id")
    let placement: ProfileWaypoint =
      value["lngLat"] != nil
      ? .atPosition(id: id, position: try value.numbers(at: "lngLat"))
      : .atDistance(id: id, distance: try value.number(at: "distance"))
    var metrics: ItinerarySegmentRowMetrics?
    if let stated = value["metrics"], !stated.isNull {
      metrics = try segmentMetrics(stated)
    }
    return ProfilePlace(
      placement, name: try value.optionalString(at: "name"),
      glyph: try value.optionalString(at: "glyph").map { RestSchema.WaypointIcon(rawValue: $0) },
      divides: value["divides"]?.boolValue, isPinned: value["pin"]?.boolValue ?? true,
      metrics: metrics, details: try details(value["details"]))
  }

  /// waypointMetricsValue writes a waypoint row's figures, each null where it has none.
  static func waypointMetricsValue(_ metrics: ItineraryWaypointRowMetrics) -> OrderedJSON {
    ProfileJSON.object([
      "altitude": GeoProfileFixtures.number(metrics.altitude),
      "ascent": GeoProfileFixtures.number(metrics.ascent),
      "descent": GeoProfileFixtures.number(metrics.descent),
      "distance": .number(metrics.distance),
      "sectionAscent": GeoProfileFixtures.number(metrics.sectionAscent),
      "sectionDescent": GeoProfileFixtures.number(metrics.sectionDescent),
      "sectionDistance": GeoProfileFixtures.number(metrics.sectionDistance),
    ])
  }

  /// waypointRow reads a waypoint row as `geo.profile.waypoint-rows` writes one, with the place's
  /// `details` beside it.
  static func waypointRow(_ value: OrderedJSON?) throws(FixtureError) -> ItineraryWaypointRow {
    guard let value, value.members != nil else {
      throw FixtureError(description: "the case's `row` is not an object")
    }
    guard let figures = value["metrics"], figures.members != nil else {
      throw FixtureError(description: "the row's `metrics` is not an object")
    }
    let id = try value.string(at: "id")
    let place = ProfilePlace(
      .atDistance(id: id, distance: try value.number(at: "to")),
      name: try value.optionalString(at: "name"),
      glyph: try value.optionalString(at: "glyph").map { RestSchema.WaypointIcon(rawValue: $0) },
      details: try details(value["details"]))
    return ItineraryWaypointRow(
      key: try value.string(at: "key"), place: place, index: try value.integer(at: "index"),
      from: try value.number(at: "from"), to: try value.number(at: "to"),
      metrics: ItineraryWaypointRowMetrics(
        distance: try figures.number(at: "distance"),
        sectionDistance: try figures.optionalNumber(at: "sectionDistance"),
        ascent: try figures.optionalNumber(at: "ascent"),
        descent: try figures.optionalNumber(at: "descent"),
        sectionAscent: try figures.optionalNumber(at: "sectionAscent"),
        sectionDescent: try figures.optionalNumber(at: "sectionDescent"),
        altitude: try figures.optionalNumber(at: "altitude")))
  }

  /// details reads what a place records, as `geo.data.itinerary-waypoints` reads it: its services,
  /// its timing, its contact and its fields, nil where the case states none.
  static func details(_ value: OrderedJSON?) throws(FixtureError) -> WaypointDetails? {
    guard let value, !value.isNull else { return nil }
    var details = WaypointDetails()
    if let amenities = value["amenities"], !amenities.isNull {
      details.amenities = try texts(amenities).map { RestSchema.WaypointAmenity(rawValue: $0) }
    }
    if let timing = value["timing"], !timing.isNull {
      details.timing = WaypointDetails.Timing(
        cutoffAt: try timing.optionalString(at: "cutoffAt").map { (text) throws(FixtureError) in
          try GeoProfileFixtures.instant(text)
        },
        stopDuration: try timing.optionalInteger(at: "stopDuration"))
    }
    if let contact = value["contact"], !contact.isNull {
      details.contact = WaypointDetails.Contact(
        address: try contact.optionalString(at: "address"),
        bookingUrl: try contact.optionalString(at: "bookingUrl"),
        email: try contact.optionalString(at: "email"),
        openingHours: try contact.optionalString(at: "openingHours"),
        phone: try contact.optionalString(at: "phone"),
        website: try contact.optionalString(at: "website"))
    }
    if let properties = value["properties"], !properties.isNull {
      guard let fields = properties.elements else {
        throw FixtureError(description: "`properties` is not an array")
      }
      var read: [WaypointDetails.Property] = []
      for field in fields {
        read.append(try property(field))
      }
      details.properties = read
    }
    return details
  }

  /// property reads one custom field, its `format` where it declares one.
  static func property(_ value: OrderedJSON?) throws(FixtureError) -> WaypointDetails.Property {
    guard let value, value.members != nil else {
      throw FixtureError(description: "a field is not an object")
    }
    return WaypointDetails.Property(
      key: try value.string(at: "key"), label: try value.string(at: "label"),
      value: try value.string(at: "value"),
      format: try value.optionalString(at: "format").map {
        RestSchema.WaypointPropertyFormat(rawValue: $0)
      })
  }

  /// fieldValue writes a written field, its `href` only where it links.
  static func fieldValue(_ field: WaypointField) -> OrderedJSON {
    var members = [
      OrderedJSON.Member(key: "key", value: .string(field.key)),
      OrderedJSON.Member(key: "label", value: .string(field.label)),
      OrderedJSON.Member(key: "value", value: .string(field.value)),
    ]
    if let href = field.href {
      members.append(OrderedJSON.Member(key: "href", value: .string(href)))
    }
    return .object(members)
  }

  /// units reads a reader's `{language, length}`, every other preference the default.
  static func units(_ value: OrderedJSON?) throws(FixtureError) -> UnitPreferences {
    guard let value, value.members != nil else {
      throw FixtureError(description: "the case's `units` is not an object")
    }
    return UnitPreferences(
      language: try value.string(at: "language"),
      length: RestSchema.UnitLength(rawValue: try value.string(at: "length")))
  }

  /// formatter is the caller's formatter a case states by what it answers, `key`, or nil where the
  /// case states none, so the caller has none.
  static func formatter(_ input: OrderedJSON, at key: String) throws(FixtureError)
    -> ((Date) -> String)?
  {
    guard let moment = try input.optionalString(at: key) else { return nil }
    return { _ in moment }
  }

  /// referencedScope is the elements' scope whose every word of the `amenities` and `waypointCard`
  /// sections is its own path, `waypointCard.phone`, so a text read through it names its word.
  static let referencedScope: ElementsScope = {
    var sections: [String: JSONValue] = [:]
    for section in ["amenities", "waypointCard"] {
      if let words = WordBundle.elements.english[section] {
        sections[section] = referenced(words, path: section)
      }
    }
    return scopeOf(.standard, stating: ElementsScopeStatement(words: .bySection(sections)))
  }()

  /// A section of words with every word replaced by its path.
  private static func referenced(_ value: JSONValue, path: String) -> JSONValue {
    guard case .object(let members) = value else { return .string(path) }
    var written: [String: JSONValue] = [:]
    for (key, member) in members {
      written[key] = referenced(member, path: "\(path).\(key)")
    }
    return .object(written)
  }

  /// word writes a text read through `referencedScope`: `{word}` where it is a word's path, else
  /// `{value}`, the text itself.
  static func word(_ text: String) -> OrderedJSON {
    let isPath =
      ["amenities.", "waypointCard."].contains { text.hasPrefix($0) }
      && text.unicodeScalars.dropFirst(text.hasPrefix("amenities.") ? 10 : 13).allSatisfy {
        ($0 >= "a" && $0 <= "z") || ($0 >= "A" && $0 <= "Z") || $0 == "-"
      }
    return .object([OrderedJSON.Member(key: isPath ? "word" : "value", value: .string(text))])
  }
}
