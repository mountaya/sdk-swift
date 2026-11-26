import GateSupport
import MountayaClient
import MountayaGeo

extension PublicRunners {
  /// dataItinerarySegments answers the legs of the case's `segments` with its `groups` collapsed.
  ///
  /// Each segment and group is built as the REST API's, from the members the fixture writes and a
  /// placeholder for every other the type requires. A leg states no running total and no
  /// difficulty, so the runner writes the `distance`, `ascent`, `descent` and `difficulty` of its
  /// metrics as the null the fixture states for every leg.
  static let dataItinerarySegments = Runner(
    id: "geo.data.itinerary-segments", table: .public
  ) { fixture, fixtureCase in
    try fixture.holdConstants([:])
    let input = fixtureCase.input
    var segments: [RestSchema.ItinerarySegment] = []
    for fields in try input.array(at: "segments") {
      segments.append(try GeoProfileFixtures.segment(fields))
    }
    var groups: [RestSchema.ItinerarySegmentGroup] = []
    for fields in try input.array(at: "groups") {
      groups.append(try GeoItineraryFixtures.group(fields))
    }
    let legs = itinerarySegments(segments, groups: groups)
    return .value(.array(legs.map(GeoItineraryFixtures.legValue)))
  }

  /// dataItineraryWaypoints answers the places of the case's `waypoints`.
  ///
  /// Each waypoint is built as the REST API's, every member read in the shape the wire's type holds
  /// and left out in any other, as no decoder of the wire's hands one over in another shape, which
  /// `geo/itinerary-waypoints.json` writes some in: what the fixture states of a member in another
  /// shape is what the type itself holds of it, and the rule reads the rest.
  static let dataItineraryWaypoints = Runner(
    id: "geo.data.itinerary-waypoints", table: .public
  ) { fixture, fixtureCase in
    try fixture.holdConstants([:])
    var waypoints: [RestSchema.ItineraryWaypoint] = []
    for fields in try fixtureCase.input.array(at: "waypoints") {
      waypoints.append(try GeoItineraryFixtures.waypoint(fields))
    }
    return .value(.array(itineraryWaypoints(waypoints).map(GeoItineraryFixtures.placeValue)))
  }

  /// dataItineraryResource plays the case's `steps` over one element watching, an engine held for
  /// the whole case, idle on client `a`'s cache until its first question, and answers each read it
  /// sent and what it shows after each step.
  ///
  /// Every client's source is a main-actor closure, so every step of the engine runs on the main
  /// actor in order, and is settled once what the element shows and the reads stand still, never
  /// by a clock (`Quiescence`).
  static let dataItineraryResource = Runner(
    id: "geo.data.itinerary-resource", table: .public
  ) { fixture, fixtureCase in
    try fixture.holdConstants([:])
    return try await playResource(
      try fixtureCase.input.array(at: "steps"), answered: fixtureCase.input["answered"])
  }

  /// dataItineraryCache plays the case's `steps`, each element that watches an engine of its own
  /// held for the whole case, and answers each read sent and what each element watching shows
  /// once every step is played. An element that reads asks once and goes: its engine is closed as
  /// soon as it is made. The capacity the fixture declares is held to the cache's own.
  static let dataItineraryCache = Runner(id: "geo.data.itinerary-cache", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants(["capacity": Double(ItineraryResourceCache.capacity)])
    return try await playCache(try fixtureCase.input.array(at: "steps"))
  }

  /// playResource plays a resource case's `steps`, every read answered with `answered` where the
  /// case states it, each snapshot then stating the summary the element shows.
  @MainActor
  private static func playResource(_ steps: [OrderedJSON], answered: OrderedJSON?) async throws
    -> RunnerOutcome
  {
    let reads = GeoItineraryFixtures.Reads()
    if let answered {
      try reads.answering(answered)
    }
    let engine = ItineraryResourceEngine(cache: try reads.cache("a"))
    var snapshots: [OrderedJSON] = []
    do {
      for step in steps {
        switch try step.string(at: "step") {
        case "configure":
          engine.configure(
            cache: try reads.cache(try step.string(at: "source")),
            itineraryId: try step.optionalString(at: "itinerary"),
            surface: try GeoItineraryFixtures.surface(step))
        case "answer":
          try reads.answer(try step.integer(at: "request"))
        case "fail":
          try reads.fail(try step.integer(at: "request"))
        case let other:
          throw FixtureError(description: "`\(other)` is no step")
        }
        await GeoItineraryFixtures.settle(reads, engines: [engine])
        snapshots.append(
          try GeoItineraryFixtures.shown(engine.state, statingSummary: answered != nil))
      }
    } catch {
      await end([engine], failing: reads)
      throw error
    }
    await end([engine], failing: reads)
    return .value(
      .object([
        OrderedJSON.Member(key: "requests", value: reads.requests),
        OrderedJSON.Member(key: "snapshots", value: .array(snapshots)),
      ]))
  }

  @MainActor
  private static func playCache(_ steps: [OrderedJSON]) async throws -> RunnerOutcome {
    let reads = GeoItineraryFixtures.Reads()
    var watching: [(element: String, engine: ItineraryResourceEngine)] = []
    do {
      for step in steps {
        switch try step.string(at: "step") {
        case "watch":
          let element = try step.string(at: "element")
          guard !watching.contains(where: { $0.element == element }) else {
            throw FixtureError(description: "the element `\(element)` watches twice")
          }
          let engine = ItineraryResourceEngine(
            cache: try reads.cache(try step.string(at: "source")),
            itineraryId: try step.optionalString(at: "itinerary"),
            surface: try GeoItineraryFixtures.surface(step))
          watching.append((element, engine))
        case "read":
          ItineraryResourceEngine(
            cache: try reads.cache(try step.string(at: "source")),
            itineraryId: try step.optionalString(at: "itinerary"),
            surface: try GeoItineraryFixtures.surface(step)
          ).close()
        case "answer":
          try reads.answer(try step.integer(at: "request"))
        case "fail":
          try reads.fail(try step.integer(at: "request"))
        case "invalidate":
          try reads.cache(try step.string(at: "source"))
            .invalidate(itineraryId: try step.optionalString(at: "itinerary"))
        case let other:
          throw FixtureError(description: "`\(other)` is no step")
        }
        await GeoItineraryFixtures.settle(reads, engines: watching.map(\.engine))
      }
      var shows: [OrderedJSON.Member] = []
      for (element, engine) in watching {
        shows.append(
          OrderedJSON.Member(key: element, value: try GeoItineraryFixtures.shown(engine.state)))
      }
      await end(watching.map(\.engine), failing: reads)
      return .value(
        .object([
          OrderedJSON.Member(key: "requests", value: reads.requests),
          OrderedJSON.Member(key: "shows", value: .object(shows)),
        ]))
    } catch {
      await end(watching.map(\.engine), failing: reads)
      throw error
    }
  }

  /// end closes a case's engines and fails every read still open, so no task is left waiting.
  @MainActor
  private static func end(
    _ engines: [ItineraryResourceEngine], failing reads: GeoItineraryFixtures.Reads
  )
    async
  {
    for engine in engines {
      engine.close()
    }
    reads.drain()
    await GeoItineraryFixtures.settle(reads, engines: engines)
  }
}
