import Foundation
import GateSupport
import MountayaClient
import MountayaGeo

extension PublicRunners {
  /// unitsConvert answers the case's `value` from one unit to another of its `quantity`, each
  /// unit read by its contract id, through the conversion Geo publishes for that quantity.
  ///
  /// The fixture's `constants` are held to the conversions themselves, each defining value read
  /// back as the conversion of one unit, so a factor the rules state is the factor it declares.
  static let unitsConvert = Runner(id: "geo.units.convert", table: .public) {
    fixture, fixtureCase in
    let celsiusZero = convertTemperature(0, from: .celsius, to: .fahrenheit)
    try fixture.holdConstants([
      "bitsPerByte": convertDataSize(1, from: .byte, to: .bit),
      "bitsPerKilobit": convertDataSize(1, from: .kilobit, to: .bit),
      "bitsPerMegabit": convertDataSize(1, from: .megabit, to: .bit),
      "bytesPerKibibyte": convertDataSize(1, from: .kibibyte, to: .byte),
      "degreesPerRadian": convertAngle(1, from: .radian, to: .degree),
      "fahrenheitOffset": celsiusZero,
      "fahrenheitPerCelsius":
        (convertTemperature(100, from: .celsius, to: .fahrenheit)
        - celsiusZero) / 100,
      "hoursPerDay": convertDuration(1, from: .day, to: .hour),
      "kibibytesPerMebibyte": convertDataSize(1, from: .mebibyte, to: .kibibyte),
      "metersPerCentimeter": convertLength(1, from: .centimeter, to: .meter),
      "metersPerFoot": convertLength(1, from: .foot, to: .meter),
      "metersPerInch": convertLength(1, from: .inch, to: .meter),
      "metersPerKilometer": convertLength(1, from: .kilometer, to: .meter),
      "metersPerMile": convertLength(1, from: .mile, to: .meter),
      "millisecondsPerSecond": convertDuration(1, from: .second, to: .millisecond),
      "minutesPerHour": convertDuration(1, from: .hour, to: .minute),
      "percentPerRatio": convertProportion(1, from: .ratio, to: .percent),
      "secondsPerHour": convertDuration(1, from: .hour, to: .second),
      "secondsPerMinute": convertDuration(1, from: .minute, to: .second),
    ])
    let input = fixtureCase.input
    let value = try input.number(at: "value")
    let from = try input.string(at: "from")
    let to = try input.string(at: "to")
    let converted: Double
    switch try input.string(at: "quantity") {
    case "length":
      converted = convertLength(value, from: try unit(from), to: try unit(to))
    case "speed":
      converted = convertSpeed(value, from: try unit(from), to: try unit(to))
    case "duration":
      converted = convertDuration(value, from: try unit(from), to: try unit(to))
    case "temperature":
      converted = convertTemperature(value, from: try unit(from), to: try unit(to))
    case "angle":
      converted = convertAngle(value, from: try unit(from), to: try unit(to))
    case "data":
      converted = convertDataSize(value, from: try unit(from), to: try unit(to))
    case "proportion":
      converted = convertProportion(value, from: try unit(from), to: try unit(to))
    case let other:
      throw FixtureError(description: "no quantity is called `\(other)`")
    }
    return .value(.number(converted))
  }

  /// unitsSlope answers the case's `value` from one slope unit to another, each read by its
  /// contract id. The fixture's `constants` are held to the conversions that state them.
  static let unitsSlope = Runner(id: "geo.units.slope", table: .public) { fixture, fixtureCase in
    try fixture.holdConstants([
      "degreesPerRadian": convertAngle(1, from: .radian, to: .degree),
      "percentPerRatio": convertSlope(1, from: .ratio, to: .percentage),
    ])
    let input = fixtureCase.input
    let converted = convertSlope(
      try input.number(at: "value"),
      from: try unit(try input.string(at: "from")),
      to: try unit(try input.string(at: "to"))
    )
    return .value(.number(converted))
  }

  /// geodesyHaversine answers the great-circle distance in meters between the case's positions
  /// `a` and `b`. The fixture's radius is held to `earthRadiusMeters`, and its degree to the
  /// angle conversion.
  static let geodesyHaversine = Runner(id: "geo.geodesy.haversine", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants([
      "degreesToRadians": convertAngle(1, from: .degree, to: .radian),
      "earthRadiusMeters": earthRadiusMeters,
    ])
    let input = fixtureCase.input
    let distance = haversineMeters(
      from: try input.numbers(at: "a"), to: try input.numbers(at: "b"))
    return .value(.number(distance))
  }

  /// terrainSlopeAspect answers the slope and the aspect at the case's `latitude` from its four
  /// `neighbours` one `spacingDegrees` away, the aspect null on flat ground. The fixture's
  /// mean-sphere degree is held to `metersPerDegreeMeanSphere`, and its turn to the angle
  /// conversion of two pi.
  static let terrainSlopeAspect = Runner(id: "geo.terrain.slope-aspect", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants([
      "degreesPerTurn": convertAngle(2 * .pi, from: .radian, to: .degree),
      "metersPerDegreeMeanSphere": metersPerDegreeMeanSphere,
    ])
    let input = fixtureCase.input
    guard let sides = input["neighbours"], sides.members != nil else {
      throw FixtureError(description: "the input's `neighbours` is not an object")
    }
    let neighbours = TerrainNeighbours(
      north: try sides.number(at: "north"),
      south: try sides.number(at: "south"),
      east: try sides.number(at: "east"),
      west: try sides.number(at: "west")
    )
    let answer = slopeAspectFromNeighbours(
      neighbours,
      latitude: try input.number(at: "latitude"),
      spacingDegrees: try input.number(at: "spacingDegrees")
    )
    return .value(
      .object([
        OrderedJSON.Member(key: "aspect", value: answer.aspect.map { .number($0) } ?? .null),
        OrderedJSON.Member(key: "slope", value: .number(answer.slope)),
      ]))
  }

  /// longitudeWrap answers `wrapLongitude(_:)`, `wrapLongitudePastRange(_:)` or
  /// `longitudeDelta(from:to:)`, as the case's `operation` names it: `wrap`, `pastRange` or
  /// `delta`.
  static let longitudeWrap = Runner(id: "geo.longitude.wrap", table: .public) { _, fixtureCase in
    let input = fixtureCase.input
    switch try input.string(at: "operation") {
    case "wrap":
      return .value(.number(wrapLongitude(try input.number(at: "longitude"))))
    case "pastRange":
      return .value(.number(wrapLongitudePastRange(try input.number(at: "longitude"))))
    case "delta":
      let delta = longitudeDelta(from: try input.number(at: "from"), to: try input.number(at: "to"))
      return .value(.number(delta))
    case let other:
      throw FixtureError(
        description: "`operation` is `wrap`, `pastRange` or `delta`, not `\(other)`")
    }
  }

  /// formatLnglat answers the case's `position`, written for a reader, or null where it names no
  /// place.
  static let formatLnglat = Runner(id: "geo.format.lnglat", table: .public) { _, fixtureCase in
    let text = formatLngLat(try fixtureCase.input.numbers(at: "position"))
    return .value(text.map { .string($0) } ?? .null)
  }

  /// corridorDistanceToSegment answers the planar distance from the case's `point` to the segment
  /// from `start` to `end`, in the degrees the cases answer in; the description's meters are a gap
  /// the contract has yet to close, and the measure in meters is `geo.corridor.meters-to-route`.
  static let corridorDistanceToSegment = Runner(
    id: "geo.corridor.distance-to-segment", table: .public
  ) { _, fixtureCase in
    let input = fixtureCase.input
    let distance = distanceToSegment(
      try input.numbers(at: "point"),
      start: try input.numbers(at: "start"),
      end: try input.numbers(at: "end")
    )
    return .value(.number(distance))
  }

  /// corridorMetersToRoute answers the distance in meters from the case's `point` to its `lines`.
  /// The fixture writes no distance as null, "where an SDK answers its infinity", so this SDK's
  /// `Double.infinity` is answered as null and every finite distance as itself. The fixture's
  /// mean-sphere degree is held to `metersPerDegreeMeanSphere`.
  static let corridorMetersToRoute = Runner(id: "geo.corridor.meters-to-route", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants(["metersPerDegreeMeanSphere": metersPerDegreeMeanSphere])
    let input = fixtureCase.input
    var lines: [GeoJSONLineString] = []
    for line in try input.array(at: "lines") {
      lines.append(try GeoFixtures.lineString(line))
    }
    let distance = metersToRoute(try input.numbers(at: "point"), lines: lines)
    return .value(distance == .infinity ? .null : .number(distance))
  }

  /// boundariesSelect answers the name of the boundary a map centred on the case's `center` locks
  /// to, of its `boundaries` in order, each built as the generated `RestSchema.Boundaries` the API
  /// answers, or null where there is none to lock to.
  static let boundariesSelect = Runner(id: "geo.boundaries.select", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    var boundaries: [RestSchema.Boundaries] = []
    for boundary in try input.array(at: "boundaries") {
      boundaries.append(
        RestSchema.Boundaries(
          bbox: try boundary.numbers(at: "bbox"), name: try boundary.string(at: "name")))
    }
    let lock = selectBoundary(boundaries, center: try input.numbers(at: "center"))
    return .value(lock.map { .string($0.name) } ?? .null)
  }

  /// timezoneViewport answers the viewport the case's `timeZone` opens on, or null where it
  /// answers none, after holding the published table to what Geo answers for every name it holds:
  /// each zone of `zoneViewports` its viewport, and each name of `reportedZoneNames` the zone it
  /// names, read as the zone whose viewport it answers.
  static let timezoneViewport = Runner(id: "geo.timezone.viewport", table: .public) {
    fixture, fixtureCase in
    let constants = fixture.constants ?? .object([])
    let zones = (constants["zoneViewports"]?.members ?? []).map {
      OrderedJSON.Member(key: $0.key, value: viewport(timeZoneViewport($0.key)))
    }
    let reported = (constants["reportedZoneNames"]?.members ?? []).map { member in
      let zone = member.value.stringValue ?? ""
      let answered = timeZoneViewport(member.key)
      let named = answered != nil && answered == timeZoneViewport(zone)
      return OrderedJSON.Member(key: member.key, value: named ? .string(zone) : .null)
    }
    try fixture.holdConstants(
      [:], values: ["reportedZoneNames": .object(reported), "zoneViewports": .object(zones)])
    return .value(viewport(timeZoneViewport(try fixtureCase.input.string(at: "timeZone"))))
  }

  /// viewport writes a viewport as the fixtures do, or null for none.
  private static func viewport(_ viewport: MapViewport?) -> OrderedJSON {
    guard let viewport else { return .null }
    return .object([
      OrderedJSON.Member(key: "center", value: GeoFixtures.numbers(viewport.center)),
      OrderedJSON.Member(key: "zoom", value: .number(viewport.zoom)),
    ])
  }

  /// unit reads a unit by its contract id, among the cases of the type the call site asks for.
  private static func unit<Unit: RawRepresentable & CaseIterable>(_ id: String)
    throws(FixtureError) -> Unit where Unit.RawValue == String
  {
    guard let unit = Unit.allCases.first(where: { $0.rawValue == id }) else {
      throw FixtureError(description: "no unit of the quantity is called `\(id)`")
    }
    return unit
  }
}
