import Foundation
import GateSupport
import MountayaClient
import MountayaGeo

extension PublicRunners {
  /// profileElevationSeries answers the series the case's `geometry` projects onto, thinned to its
  /// `maxPoints` where it names one and to the declared ceiling where it names none. The ceiling is
  /// held to the published constant and read through the rule as well: a line one vertex over it
  /// comes back at exactly the ceiling, both its ends kept.
  static let profileElevationSeries = Runner(
    id: "geo.profile.elevation-series", table: .public
  ) { fixture, fixtureCase in
    try fixture.holdConstants(["maxPoints": Double(maxProfilePoints)])
    // A line that climbs a meter a vertex from zero, so an elevation names the vertex it was read
    // at.
    let overTheCeiling = buildElevationSeries(
      .lineString(
        GeoJSONLineString(
          coordinates: (0...maxProfilePoints).map { [Double($0) / 1_000, 45, Double($0)] }))
    ).points
    guard overTheCeiling.count == maxProfilePoints,
      overTheCeiling.first?.elevation == 0,
      overTheCeiling.last?.elevation == Double(maxProfilePoints)
    else {
      throw FixtureError(
        description: "a line one vertex over the ceiling is not thinned to it, both ends kept")
    }
    let input = fixtureCase.input
    var geometry: GeoJSONGeometry?
    if let written = input["geometry"], !written.isNull {
      geometry = try GeoFixtures.geometry(written)
    }
    let series =
      try input.optionalInteger(at: "maxPoints").map {
        buildElevationSeries(geometry, maxPoints: $0)
      }
      ?? buildElevationSeries(geometry)
    return .value(GeoProfileFixtures.seriesValue(series))
  }

  /// profileTotals answers the totals of the case's `series`. The noise threshold, the grade window
  /// and the series' ceiling are held to the published constants; the narrowest window a chart is
  /// drawn over is `geo.profile.window-clamp`'s, which holds it.
  static let profileTotals = Runner(id: "geo.profile.totals", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants([
      "elevationNoiseThresholdMeters": elevationNoiseThresholdMeters,
      "gradeWindowMeters": gradeWindowMeters,
      "maxProfilePoints": Double(maxProfilePoints),
    ])
    let series = try GeoProfileFixtures.series(fixtureCase.input["series"])
    return .value(GeoProfileFixtures.totalsValue(MountayaGeo.profileTotals(series)))
  }

  /// profileRangeTotals answers the totals of the stretch the case's `range` names on its
  /// `series`.
  static let profileRangeTotals = Runner(id: "geo.profile.range-totals", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants([
      "elevationNoiseThresholdMeters": elevationNoiseThresholdMeters,
      "gradeWindowMeters": gradeWindowMeters,
    ])
    let input = fixtureCase.input
    guard let range = input["range"], range.members != nil else {
      throw FixtureError(description: "the case has no `range`")
    }
    let totals = rangeTotals(
      try GeoProfileFixtures.series(input["series"]),
      from: try range.number(at: "from"),
      to: try range.number(at: "to")
    )
    return .value(GeoProfileFixtures.totalsValue(totals))
  }

  /// profileClimbs answers, for a case with `points`, the climbs on them in order of their start,
  /// and for one with a `lengthMeters` and an `avgGradePercent`, that climb's category, or null.
  /// The windows, the grades and the shortest climb are held to the published constants, and the
  /// score thresholds to each category's minimum score.
  static let profileClimbs = Runner(id: "geo.profile.climbs", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants(
      [
        "closeGradePercent": climbCloseGradePercent,
        "closeWindowKm": climbCloseWindowKm,
        "minClimbLengthKm": minClimbLengthKm,
        "minGradePercent": minClimbGradePercent,
        "openGradePercent": climbOpenGradePercent,
        "openWindowKm": climbOpenWindowKm,
      ],
      values: [
        "scoreThresholds": .object(
          ClimbCategory.allCases.map {
            OrderedJSON.Member(key: $0.id, value: .number($0.minimumScore))
          })
      ]
    )
    let input = fixtureCase.input
    guard input["points"] != nil else {
      let category = climbCategoryFor(
        lengthMeters: try input.number(at: "lengthMeters"),
        avgGradePercent: try input.number(at: "avgGradePercent"))
      return .value(GeoProfileFixtures.text(category?.id))
    }
    var points: [RouteProfilePoint] = []
    for point in try input.array(at: "points") {
      points.append(
        RouteProfilePoint(
          distanceKm: try point.number(at: "distanceKm"),
          elevation: try point.number(at: "elevation")))
    }
    return .value(
      .array(
        detectClimbs(points).map { climb in
          .object([
            OrderedJSON.Member(key: "avgGradePercent", value: .number(climb.avgGradePercent)),
            OrderedJSON.Member(key: "category", value: .string(climb.category.id)),
            OrderedJSON.Member(key: "endKm", value: .number(climb.endKm)),
            OrderedJSON.Member(key: "peakElevation", value: .number(climb.peakElevation)),
            OrderedJSON.Member(key: "startKm", value: .number(climb.startKm)),
          ])
        }))
  }

  /// profileResolveWaypoints answers the case's `waypoints` placed on its `geometry`, each given at
  /// a `lngLat` or at a `distance`, as the waypoint's id, the placement's key and its distance.
  static let profileResolveWaypoints = Runner(
    id: "geo.profile.resolve-waypoints", table: .public
  ) { fixture, fixtureCase in
    try fixture.holdConstants([
      "belongingMeters": waypointBelongingMeters,
      "proximityMeters": waypointProximityMeters,
    ])
    let input = fixtureCase.input
    var waypoints: [ProfileWaypoint] = []
    for waypoint in try input.array(at: "waypoints") {
      let id = try waypoint.string(at: "id")
      if waypoint["lngLat"] != nil {
        waypoints.append(.atPosition(id: id, position: try waypoint.numbers(at: "lngLat")))
      } else {
        waypoints.append(.atDistance(id: id, distance: try waypoint.number(at: "distance")))
      }
    }
    var geometry: GeoJSONGeometry?
    if let written = input["geometry"], !written.isNull {
      geometry = try GeoFixtures.geometry(written)
    }
    return .value(
      .array(
        resolveWaypoints(geometry, waypoints: waypoints).map { placed in
          .object([
            OrderedJSON.Member(key: "distance", value: .number(placed.distance)),
            OrderedJSON.Member(key: "id", value: .string(placed.waypoint.id)),
            OrderedJSON.Member(key: "key", value: .string(placed.key)),
          ])
        }))
  }

  /// profileInfoBands answers the bands the case's `segments` yield on the itinerary's axis. Each
  /// segment is built as the REST API's, its `geojson` the fixture's geometry, and its entries are
  /// the fixture's `info`, an analysis of no one wire name, handed to the rule as the analysis it
  /// reads: words, such as a surface's, as `String`, and numbers, such as a slope's, as `Double`,
  /// the type the wire's analysis of each holds. A Swift segment is a value with no identity to find
  /// it by, so each is named by its place in the case, an id no rule reads, and its entries are
  /// found by that name.
  static let profileInfoBands = Runner(id: "geo.profile.info-bands", table: .public) {
    _, fixtureCase in
    let written = try fixtureCase.input.array(at: "segments")
    let values = try written.flatMap { try $0.array(at: "info") }.compactMap { $0["value"] }
    if !values.isEmpty, values.allSatisfy({ $0.numberValue != nil }) {
      return .value(
        try infoBands(written) {
          .number($0)
        } read: {
          try $0.number(at: "value")
        })
    }
    return .value(
      try infoBands(written) {
        .string($0)
      } read: {
        try $0.string(at: "value")
      })
  }

  /// infoBands answers the bands `written` segments yield, their entries' values read by `read` and
  /// each band's value written back by `write`.
  private static func infoBands<Value: Equatable>(
    _ written: [OrderedJSON], write: (Value) -> OrderedJSON, read: (OrderedJSON) throws -> Value
  ) throws -> OrderedJSON {
    var segments: [RestSchema.ItinerarySegment] = []
    var entries: [String: [InfoRange<Value>]] = [:]
    for (index, fields) in written.enumerated() {
      let segment = try GeoProfileFixtures.segment(fields, id: "segment-\(index)")
      var ranges: [InfoRange<Value>] = []
      for entry in try fields.array(at: "info") {
        ranges.append(
          InfoRange(
            fromIndex: try entry.integer(at: "from_index"),
            toIndex: try entry.integer(at: "to_index"),
            value: try read(entry)))
      }
      segments.append(segment)
      entries[segment.id] = ranges
    }
    let bands = buildInfoBands(segments) { entries[$0.id] }
    return .array(
      bands.map { band in
        .object([
          OrderedJSON.Member(key: "endKm", value: .number(band.endKm)),
          OrderedJSON.Member(key: "startKm", value: .number(band.startKm)),
          OrderedJSON.Member(key: "value", value: write(band.value)),
        ])
      })
  }

  /// profileDistanceTicks answers the stops a distance axis over the case's `range` is labelled
  /// at, in the reader's `length`, at the case's `target` count where it names one.
  static let profileDistanceTicks = Runner(id: "geo.profile.distance-ticks", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants(["defaultTarget": Double(defaultDistanceTickCount)])
    let input = fixtureCase.input
    guard let range = input["range"], range.members != nil else {
      throw FixtureError(description: "the case has no `range`")
    }
    let from = try range.number(at: "from")
    let to = try range.number(at: "to")
    let length = RestSchema.UnitLength(rawValue: try input.string(at: "length"))
    let ticks =
      try input.optionalInteger(at: "target").map {
        distanceTicks(from: from, to: to, length: length, target: $0)
      } ?? distanceTicks(from: from, to: to, length: length)
    return .value(
      .array(
        ticks.map { tick in
          .object([
            OrderedJSON.Member(key: "fractionDigits", value: .number(Double(tick.fractionDigits))),
            OrderedJSON.Member(key: "meters", value: .number(tick.meters)),
            OrderedJSON.Member(key: "value", value: .number(tick.value)),
          ])
        }))
  }
}
