import GateSupport
import MountayaClient
import MountayaGeo

extension PublicRunners {
  /// navigationSteps answers the case's `steps`, as the `surface` it names sends them, read into
  /// the one vocabulary over a geometry of `coordinateCount` vertices. Each surface's steps are
  /// written as its JSON, the Data API's `DirectionsStep` in camelCase and REST's
  /// `ItineraryDirectionsStep` in snake case, and decoded by the generated type's own decoder, so a
  /// maneuver neither spells reaches the adapter as written. The answer is whether the list was
  /// refused and the steps read.
  static let navigationSteps = Runner(id: "geo.navigation.steps", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    let coordinateCount = try input.integer(at: "coordinateCount")
    let written = input["steps"].flatMap { $0.isNull ? nil : $0 }
    let reading: NavigationStepsReading
    switch try input.string(at: "surface") {
    case "data":
      let steps = try written.map { value throws(FixtureError) in
        try GeoFixtures.decoded([DataSchema.DirectionsStep].self, from: value)
      }
      reading = readDirectionsSteps(steps, coordinateCount: coordinateCount)
    case "rest":
      let steps = try written.map { value throws(FixtureError) in
        try GeoFixtures.decoded([RestSchema.ItineraryDirectionsStep].self, from: value)
      }
      reading = readItineraryDirectionsSteps(steps, coordinateCount: coordinateCount)
    case let other:
      throw FixtureError(description: "`\(other)` is no surface")
    }
    return .value(
      .object([
        OrderedJSON.Member(key: "refused", value: .bool(reading.refused)),
        OrderedJSON.Member(
          key: "steps", value: .array(reading.steps.map(NavigationFixtures.written))),
      ]))
  }

  /// navigationSteplessRoute answers the steps a route of the case's `line`, `duration` and
  /// `steps` is followed by, as `followedRouteOf(_:)` answers them, or null for a route there is
  /// none to follow.
  static let navigationSteplessRoute = Runner(
    id: "geo.navigation.stepless-route", table: .public
  ) { _, fixtureCase in
    let input = fixtureCase.input
    let route = NavigationRoute(
      line: try input.positions(at: "line"), steps: try NavigationFixtures.steps(input),
      duration: try input.optionalNumber(at: "duration"))
    guard let followed = followedRouteOf(route) else { return .value(.null) }
    return .value(.array(followed.steps.map(NavigationFixtures.written)))
  }

  /// navigationItineraryRoute answers the route `readItineraryRoute(_:waypoints:)` joins the
  /// case's segments into over its waypoints, or null where it answers none, after holding the
  /// fixture's `proximityMeters` to `waypointProximityMeters`.
  ///
  /// Each segment and each waypoint is the wire's, built from the members the case writes, its id
  /// and its mode among them, and a placeholder for every other the type requires, which the rule
  /// never reads (`NavigationFixtures.segment(_:)`, `GeoItineraryFixtures.waypoint(_:)`).
  static let navigationItineraryRoute = Runner(
    id: "geo.navigation.itinerary-route", table: .public
  ) { fixture, fixtureCase in
    try fixture.holdConstants(["proximityMeters": waypointProximityMeters])
    let input = fixtureCase.input
    var segments: [RestSchema.ItinerarySegment] = []
    for fields in try input.array(at: "segments") {
      segments.append(try NavigationFixtures.segment(fields))
    }
    var waypoints: [RestSchema.ItineraryWaypoint] = []
    for fields in try input.array(at: "waypoints") {
      var waypoint = try GeoItineraryFixtures.waypoint(fields)
      waypoint.mode = RestSchema.WaypointMode(rawValue: try fields.string(at: "mode"))
      waypoints.append(waypoint)
    }
    guard let route = readItineraryRoute(segments, waypoints: waypoints) else {
      return .value(.null)
    }
    return .value(
      .object([
        OrderedJSON.Member(key: "duration", value: NavigationFixtures.number(route.duration)),
        OrderedJSON.Member(key: "line", value: .array(route.line.map(GeoFixtures.numbers))),
        OrderedJSON.Member(
          key: "steps", value: .array(route.steps.map(NavigationFixtures.written))),
      ]))
  }

  /// navigationInstructionKeys answers the copy key the case's step is said with, and the
  /// arguments it takes, by name. The case writes a step's `maneuver`, `name` and `exitNumber`, the
  /// members an instruction reads, and the runner builds the step with a range of vertex 0 alone,
  /// which no instruction reads. The fixture's `keys`, every key with the arguments it takes in
  /// order, is held to `NavigationInstructionKey`'s cases.
  static let navigationInstructionKeys = Runner(
    id: "geo.navigation.instruction-keys", table: .public
  ) { fixture, fixtureCase in
    try fixture.holdConstants(
      [:],
      values: [
        "keys": .object(
          NavigationInstructionKey.allCases.map {
            OrderedJSON.Member(key: $0.id, value: GeoFixtures.texts($0.arguments.map(\.id)))
          })
      ])
    let input = fixtureCase.input
    let instruction = stepInstruction(
      NavigationStep(
        fromIndex: 0, toIndex: 0,
        maneuver: RestSchema.ManeuverType(rawValue: try input.string(at: "maneuver")),
        name: try input.optionalString(at: "name"),
        exitNumber: try input.optionalInteger(at: "exitNumber")))
    let arguments = instruction.key.arguments.map { argument in
      switch argument {
      case .exit:
        OrderedJSON.Member(
          key: argument.id, value: instruction.exit.map { .number(Double($0)) } ?? .null)
      case .name:
        OrderedJSON.Member(key: argument.id, value: instruction.name.map { .string($0) } ?? .null)
      }
    }
    return .value(
      .object([
        OrderedJSON.Member(key: "arguments", value: .object(arguments)),
        OrderedJSON.Member(key: "key", value: .string(instruction.key.id)),
      ]))
  }

  /// navigationProgress answers where a traveller at the case's `position` stands on a route of
  /// its `line` and `steps`, `previous` meters along it, and what is left. The case's steps are
  /// the ones the route is followed by (`geo.navigation.stepless-route`), so the route is built
  /// through `followedRouteOf(_:)`, which keeps steps that tile their line as they are.
  static let navigationProgress = Runner(id: "geo.navigation.progress", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    guard
      let route = followedRouteOf(
        NavigationRoute(
          line: try input.positions(at: "line"), steps: try NavigationFixtures.steps(input)))
    else {
      throw FixtureError(description: "the case's line holds no vertex")
    }
    let progress = navigationProgressAt(
      route, position: try input.numbers(at: "position"),
      previous: try input.number(at: "previous"))
    func remainder(_ remainder: NavigationRemainder) -> OrderedJSON {
      .object([
        OrderedJSON.Member(key: "distance", value: .number(remainder.distance)),
        OrderedJSON.Member(key: "duration", value: NavigationFixtures.number(remainder.duration)),
      ])
    }
    return .value(
      .object([
        OrderedJSON.Member(key: "along", value: .number(progress.along)),
        OrderedJSON.Member(
          key: "next", value: NavigationFixtures.number(progress.next.map(Double.init))),
        OrderedJSON.Member(key: "step", value: .number(Double(progress.step))),
        OrderedJSON.Member(key: "toArrival", value: remainder(progress.toArrival)),
        OrderedJSON.Member(key: "toManeuver", value: remainder(progress.toManeuver)),
      ]))
  }
}

/// NavigationFixtures reads and writes a step of the navigation vocabulary as the fixtures write
/// one: `fromIndex`, `toIndex`, `maneuver`, `name`, `distance`, `duration` and `exitNumber`.
enum NavigationFixtures {
  /// steps reads the case's `steps`, none where the case states none.
  static func steps(_ input: OrderedJSON) throws(FixtureError) -> [NavigationStep] {
    guard input["steps"] != nil else { return [] }
    var steps: [NavigationStep] = []
    for value in try input.array(at: "steps") {
      steps.append(try step(value))
    }
    return steps
  }

  /// step reads one step a fixture writes; a member it leaves out or writes null is none, and a
  /// range is required.
  static func step(_ value: OrderedJSON) throws(FixtureError) -> NavigationStep {
    guard value.members != nil else { throw FixtureError(description: "a step is not an object") }
    return NavigationStep(
      fromIndex: try value.integer(at: "fromIndex"),
      toIndex: try value.integer(at: "toIndex"),
      maneuver: RestSchema.ManeuverType(rawValue: try value.string(at: "maneuver")),
      name: try value.optionalString(at: "name"),
      distance: try value.optionalNumber(at: "distance"),
      duration: try value.optionalNumber(at: "duration"),
      exitNumber: try value.optionalInteger(at: "exitNumber"))
  }

  /// written is a step as the fixtures write one, every member stated and null where it holds
  /// none.
  static func written(_ step: NavigationStep) -> OrderedJSON {
    .object([
      OrderedJSON.Member(key: "distance", value: number(step.distance)),
      OrderedJSON.Member(key: "duration", value: number(step.duration)),
      OrderedJSON.Member(key: "exitNumber", value: number(step.exitNumber.map(Double.init))),
      OrderedJSON.Member(key: "fromIndex", value: .number(Double(step.fromIndex))),
      OrderedJSON.Member(key: "maneuver", value: .string(step.maneuver.rawValue)),
      OrderedJSON.Member(key: "name", value: step.name.map { .string($0) } ?? .null),
      OrderedJSON.Member(key: "toIndex", value: .number(Double(step.toIndex))),
    ])
  }

  /// number is a figure as a fixture writes it, null where there is none.
  static func number(_ value: Double?) -> OrderedJSON {
    value.map { .number($0) } ?? .null
  }

  /// segment builds an itinerary's segment as the REST API answers one from the members a case
  /// writes, `id`, `mode`, `position`, `geojson`, `steps` and `duration`, and a placeholder for
  /// every other the type requires (`GeoFixtures.segment(id:position:geojson:)`).
  static func segment(_ fields: OrderedJSON) throws(FixtureError) -> RestSchema.ItinerarySegment {
    guard fields.members != nil else {
      throw FixtureError(description: "a segment is not an object")
    }
    var geojson: GeoJSONGeometry?
    if let geometry = fields["geojson"], !geometry.isNull {
      geojson = try GeoFixtures.geometry(geometry)
    }
    var segment = GeoFixtures.segment(
      id: try fields.string(at: "id"), position: try fields.integer(at: "position"),
      geojson: geojson)
    segment.mode = RestSchema.SegmentMode(rawValue: try fields.string(at: "mode"))
    segment.duration = try fields.optionalNumber(at: "duration")
    if let steps = fields["steps"], !steps.isNull {
      var read: [RestSchema.ItineraryDirectionsStep] = []
      for step in try fields.array(at: "steps") {
        read.append(
          RestSchema.ItineraryDirectionsStep(
            distance: try step.number(at: "distance"),
            duration: try step.number(at: "duration"),
            exit_number: try step.optionalInteger(at: "exit_number"),
            from_index: try step.integer(at: "from_index"),
            name: try step.string(at: "name"),
            to_index: try step.integer(at: "to_index"),
            type: RestSchema.ManeuverType(rawValue: try step.string(at: "type"))))
      }
      segment.steps = read
    }
    return segment
  }
}
