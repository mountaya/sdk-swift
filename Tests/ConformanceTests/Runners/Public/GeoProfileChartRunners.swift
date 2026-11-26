import Foundation
import GateSupport
import MountayaClient
import MountayaGeo

extension PublicRunners {
  /// profilePlotScale answers where the case's `distance` and `elevation` are drawn in the
  /// profile's square, over its `window` where it states one. The square, its insets and its
  /// baseline are held to the published constants.
  static let profilePlotScale = Runner(id: "geo.profile.plot-scale", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants([
      "baseline": profileBaseline, "bottomInset": profileBottomInset,
      "topInset": profileTopInset, "viewBox": profileViewBox,
    ])
    let input = fixtureCase.input
    let window = try ProfileJSON.window(input["window"])
    let x = profileX(
      try input.number(at: "distance"), totalDistance: try input.number(at: "totalDistance"),
      window: window)
    let y = profileY(
      try input.number(at: "elevation"), domain: try ProfileJSON.domain(input["domain"]))
    return .value(ProfileJSON.object(["x": .number(x), "y": .number(y)]))
  }

  /// profileDomain answers the domain the case's `series` is drawn against under its `anchor`,
  /// `route` where it states none, over its `window`, and the ticks its scale is labelled at. The
  /// empty domain, the narrowest span and the rounding steps are held to the published ones.
  static let profileDomain = Runner(id: "geo.profile.domain", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants(
      ["minSpanMeters": minDomainSpanMeters],
      values: [
        "emptyDomain": ProfileJSON.domainValue(emptyElevationDomain),
        "roundingSteps": .array(
          domainRoundingSteps.map {
            ProfileJSON.object([
              "stepMeters": .number($0.stepMeters),
              "uptoSpanMeters": GeoProfileFixtures.number($0.uptoSpanMeters),
            ])
          }),
      ])
    let input = fixtureCase.input
    let anchorName = try input.optionalString(at: "anchor") ?? ProfileAnchor.route.rawValue
    guard let anchor = ProfileAnchor(rawValue: anchorName) else {
      throw FixtureError(description: "`\(anchorName)` is no anchor")
    }
    let domain = anchoredDomain(
      try GeoProfileFixtures.series(input["series"]), anchor: anchor,
      window: try ProfileJSON.window(input["window"]))
    return .value(
      ProfileJSON.object([
        "max": .number(domain.max), "min": .number(domain.min),
        "ticks": GeoFixtures.numbers(domainTicks(domain)),
      ]))
  }

  /// profileChartPath answers the line the case's `series` is drawn as against its `domain`, over
  /// its `window`, as points, and the area under it as commands.
  static let profileChartPath = Runner(id: "geo.profile.chart-path", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    let series = try GeoProfileFixtures.series(input["series"])
    let domain = try ProfileJSON.domain(input["domain"])
    let window = try ProfileJSON.window(input["window"])
    let line = profilePolyline(series, domain: domain, window: window).map {
      GeoFixtures.numbers([$0.x, $0.y])
    }
    let area = profileAreaPath(series, domain: domain, window: window).map { command in
      switch command {
      case .move(let point): OrderedJSON.array([.string("M"), .number(point.x), .number(point.y)])
      case .line(let point): OrderedJSON.array([.string("L"), .number(point.x), .number(point.y)])
      case .close: OrderedJSON.array([.string("Z")])
      }
    }
    return .value(ProfileJSON.object(["area": .array(area), "line": .array(line)]))
  }

  /// profileCurveStops answers the gradient the case's coloured `stretches` paint the curve with,
  /// over its `window` where it states one.
  static let profileCurveStops = Runner(id: "geo.profile.curve-stops", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    var stretches: [CurveColor] = []
    for stretch in try input.array(at: "stretches") {
      stretches.append(
        CurveColor(
          from: try stretch.number(at: "from"), to: try stretch.number(at: "to"),
          color: try stretch.string(at: "color")))
    }
    let stops = curveStops(
      stretches, totalDistance: try input.number(at: "totalDistance"),
      window: try ProfileJSON.window(input["window"]))
    return .value(
      .array(
        stops.map {
          ProfileJSON.object([
            "color": GeoProfileFixtures.text($0.color), "offset": .number($0.offset),
          ])
        }))
  }

  /// profileStretchAt answers the name of the stretch the case's `distance` reads among its
  /// named `stretches`, or null. A stretch is a classified one whose word is its name.
  static let profileStretchAt = Runner(id: "geo.profile.stretch-at", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    var stretches: [ProfileClass] = []
    for stretch in try input.array(at: "stretches") {
      stretches.append(
        ProfileClass(
          from: try stretch.number(at: "from"), to: try stretch.number(at: "to"), color: "",
          label: try stretch.string(at: "name")))
    }
    let found = stretchAt(stretches, distance: try input.number(at: "distance"))
    return .value(GeoProfileFixtures.text(found?.label))
  }

  /// profileSlopeStretches answers the stretches the case's `series` is painted in by its own
  /// steepness, each its ends, its bucket's key and its colour. The buckets and the grade window
  /// are held to the published ones.
  static let profileSlopeStretches = Runner(id: "geo.profile.slope-stretches", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants(
      ["gradeWindowMeters": gradeWindowMeters],
      values: [
        "buckets": .array(
          slopeBuckets.map {
            ProfileJSON.object([
              "color": .string($0.color), "from": .number($0.from), "key": .string($0.key),
            ])
          })
      ])
    let series = try GeoProfileFixtures.series(fixtureCase.input["series"])
    return .value(
      .array(
        slopeStretches(series.points).map {
          ProfileJSON.object([
            "color": .string($0.color), "from": .number($0.from), "key": .string($0.label),
            "to": .number($0.to),
          ])
        }))
  }

  /// profileGradeAt answers the grade at the case's `distance` along its `series`, or null. The
  /// grade window is held to the published constant.
  static let profileGradeAt = Runner(id: "geo.profile.grade-at", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants(["gradeWindowMeters": gradeWindowMeters])
    let input = fixtureCase.input
    let grade = gradeAt(
      try GeoProfileFixtures.series(input["series"]).points,
      distance: try input.number(at: "distance"))
    return .value(GeoProfileFixtures.number(grade))
  }

  /// profileScrubGrid answers the columns a scrub over the case's `window` reads as runs of one
  /// sample, and the distance each column of its `centres` stands for. The column count is held to
  /// the published constant.
  static let profileScrubGrid = Runner(id: "geo.profile.scrub-grid", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants(["columns": Double(profileScrubColumns)])
    let input = fixtureCase.input
    guard let window = try ProfileJSON.window(input["window"]) else {
      throw FixtureError(description: "the case states no `window`")
    }
    let grid = scrubGrid(try GeoProfileFixtures.series(input["series"]).points, window: window)
    var runs: [(first: Int, last: Int, sample: Int?)] = []
    for (column, sample) in grid.enumerated() {
      if let open = runs.last, open.sample == sample {
        runs[runs.count - 1].last = column
      } else {
        runs.append((column, column, sample))
      }
    }
    var centres: [Double] = []
    for column in try input.array(at: "centres") {
      guard let number = column.numberValue, let index = Int(exactly: number) else {
        throw FixtureError(description: "a column of `centres` is no whole number")
      }
      centres.append(scrubDistance(column: index, window: window))
    }
    return .value(
      ProfileJSON.object([
        "centres": GeoFixtures.numbers(centres),
        "runs": .array(
          runs.map {
            ProfileJSON.object([
              "first": .number(Double($0.first)), "last": .number(Double($0.last)),
              "sample": GeoProfileFixtures.number($0.sample.map(Double.init)),
            ])
          }),
      ]))
  }

  /// profileWindowClamp answers the window a profile draws for the case's `window` over an
  /// itinerary of its `totalDistance`. The narrowest window is held to the published constant.
  static let profileWindowClamp = Runner(id: "geo.profile.window-clamp", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants(["minSpanMeters": minRangeSpanMeters])
    let input = fixtureCase.input
    guard let window = try ProfileJSON.window(input["window"]) else {
      throw FixtureError(description: "the case states no `window`")
    }
    let drawn = clampRange(window, totalDistance: try input.number(at: "totalDistance"))
    return .value(ProfileJSON.object(["from": .number(drawn.from), "to": .number(drawn.to)]))
  }

  /// profileCurvePlacement answers where the case's `waypoints`, each placed at its distance,
  /// stand on its `series` drawn against its `domain` over its `window`: the pins, the dividers
  /// and the cut-offs. A place's `pin`, `divides`, `name` and `cutoffAt` are read as the profile's
  /// own place states them, and a cut-off is written back as the instant the fixture writes.
  static let profileCurvePlacement = Runner(id: "geo.profile.curve-placement", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    var places: [ProfilePlace] = []
    for waypoint in try input.array(at: "waypoints") {
      var details: WaypointDetails?
      if let cutoff = try waypoint.optionalString(at: "cutoffAt") {
        details = WaypointDetails(
          timing: WaypointDetails.Timing(cutoffAt: try GeoProfileFixtures.instant(cutoff)))
      }
      places.append(
        ProfilePlace(
          .atDistance(
            id: try waypoint.string(at: "id"), distance: try waypoint.number(at: "distance")),
          name: try waypoint.optionalString(at: "name"),
          divides: waypoint["divides"]?.boolValue,
          isPinned: waypoint["pin"]?.boolValue ?? true,
          details: details))
    }
    guard let window = try ProfileJSON.window(input["window"]) else {
      throw FixtureError(description: "the case states no `window`")
    }
    let placement = placeOnCurve(
      try GeoProfileFixtures.series(input["series"]), geometry: nil,
      domain: try ProfileJSON.domain(input["domain"]), window: window, places: places)
    return .value(
      ProfileJSON.object([
        "cutoffs": .array(
          placement.cutoffs.map {
            ProfileJSON.object([
              "cutoffAt": .string(ProfileJSON.instant($0.cutoffAt)), "key": .string($0.key),
              "x": .number($0.x),
            ])
          }),
        "dividers": .array(
          placement.dividers.map {
            ProfileJSON.object([
              "key": .string($0.key), "name": .string($0.name), "x": .number($0.x),
              "y": GeoProfileFixtures.number($0.y),
            ])
          }),
        "pins": .array(
          placement.pins.map {
            ProfileJSON.object([
              "altitude": .number($0.altitude), "key": .string($0.key), "x": .number($0.x),
              "y": .number($0.y),
            ])
          }),
      ]))
  }

  /// profileAxisLabelCulling answers the keys of the case's laid-out `boxes` left undrawn. The
  /// gutter is held to the published constant.
  static let profileAxisLabelCulling = Runner(
    id: "geo.profile.axis-label-culling", table: .public
  ) { fixture, fixtureCase in
    try fixture.holdConstants(["gutterPixels": axisLabelGutter])
    var boxes: [AxisLabelBox] = []
    for box in try fixtureCase.input.array(at: "boxes") {
      boxes.append(
        AxisLabelBox(
          key: try box.string(at: "key"), left: try box.number(at: "left"),
          right: try box.number(at: "right")))
    }
    return .value(GeoFixtures.texts(cullCrowdedLabels(boxes)))
  }
}

/// ProfileJSON reads the values the profile's chart fixtures write, and writes answers in their
/// shapes.
enum ProfileJSON {
  /// object writes the members given, in the order given.
  static func object(_ members: KeyValuePairs<String, OrderedJSON>) -> OrderedJSON {
    .object(members.map { OrderedJSON.Member(key: $0.key, value: $0.value) })
  }

  /// window reads a case's `{from, to}` window, nil where the case states none.
  static func window(_ value: OrderedJSON?) throws(FixtureError) -> ProfileRange? {
    guard let value, !value.isNull else { return nil }
    return ProfileRange(from: try value.number(at: "from"), to: try value.number(at: "to"))
  }

  /// domain reads a case's `{min, max}` elevation domain.
  static func domain(_ value: OrderedJSON?) throws(FixtureError) -> ElevationDomain {
    guard let value, value.members != nil else {
      throw FixtureError(description: "the case's `domain` is not an object")
    }
    return ElevationDomain(min: try value.number(at: "min"), max: try value.number(at: "max"))
  }

  /// domainValue writes a domain as `{max, min}`.
  static func domainValue(_ domain: ElevationDomain) -> OrderedJSON {
    object(["max": .number(domain.max), "min": .number(domain.min)])
  }

  /// instant writes an instant as RFC 3339 in UTC, whole seconds, as the fixtures write one.
  static func instant(_ date: Date) -> String {
    date.formatted(Date.ISO8601FormatStyle())
  }
}
