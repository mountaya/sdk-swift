import MountayaClient
import Observation
import Testing

@testable import MountayaGeo

/// The engine contract every `NavigationEngine` answers alike, held here on the one engine this
/// product ships, the scripted one, which follows a route over the same rules as every other: the
/// three edges the contract leaves open (decided as `sdk-typescript`'s engine decides them), and
/// what the state reports, when, and in what order.
@Suite("NavigationEngine")
@MainActor
struct NavigationEngineTests {
  private struct Unreachable: Error, Equatable {
    let reason: String
  }

  /// eastward is two stretches east along the equator, followed as a departure and an arrival.
  private let eastward = NavigationRoute(line: [[0, 0], [0.01, 0], [0.02, 0]], duration: 1_200)

  private var length: Double { routeLengthMeters(eastward.line) }

  /// north is a position this many meters north of the equator at a longitude.
  private func north(_ meters: Double, atLongitude longitude: Double) -> [Double] {
    [longitude, meters / metersPerDegreeMeanSphere]
  }

  /// navigating is an engine started and answered with a route.
  private func navigating(_ route: NavigationRoute? = nil) throws -> ScriptedNavigationEngine<
    String
  > {
    let engine = ScriptedNavigationEngine<String>()
    engine.start("summit")
    try engine.sent[0].answer(route ?? eastward)
    return engine
  }

  /// recorded is every state an engine reports while `commands` run, its current one first, as a
  /// reader that misses none sees them. The engine is closed after, which ends the stream.
  private func recorded(
    _ engine: some NavigationEngine<String>, commands: () throws -> Void
  ) async throws -> [NavigationState] {
    let stream = engine.subscribe()
    try commands()
    engine.close()
    var seen: [NavigationState] = []
    for await state in stream {
      seen.append(state)
    }
    return seen
  }

  @Test("an engine is idle and asks for nothing until it is started")
  func idleUntilStarted() {
    let engine = ScriptedNavigationEngine<String>()

    #expect(engine.state == .idle)
    #expect(engine.sent.isEmpty)
  }

  @Test("a start routes, and the route that lands is followed by its steps")
  func startRoutes() throws {
    let engine = ScriptedNavigationEngine<String>()

    engine.start("summit")
    #expect(engine.state.status == .routing)
    #expect(engine.sent.map(\.request) == ["summit"])

    try engine.sent[0].answer(eastward)
    #expect(engine.state.status == .navigating)
    #expect(engine.state.route?.line == eastward.line)
    #expect(
      engine.state.route?.steps.map(\.maneuver) == [.depart, .goal])
  }

  /// N12, the arrival: raised where the traveller is on the route and progress stands at its end.
  @Test("a traveller arrives on the route, with progress at its end")
  func arrives() throws {
    let engine = try navigating()

    try engine.setPosition(north(10, atLongitude: 0.005))
    #expect(engine.state.status == .navigating)
    #expect(isClose(engine.state.progress?.toArrival.duration ?? .nan, 900, within: 1e-6))

    // Past the end, and within the threshold of it: the foot stands on the last vertex.
    try engine.setPosition([0.0204, 0])
    #expect(engine.state.status == .arrived)
    #expect(engine.state.progress?.toArrival == NavigationRemainder(distance: 0, duration: 0))
  }

  @Test("a traveller who stops short never arrives")
  func stopsShort() throws {
    let engine = try navigating()

    try engine.setPosition([0.0199, 0])

    #expect(engine.state.status == .navigating)
    #expect((engine.state.progress?.toArrival.distance ?? 0) > 0)
  }

  /// At the end's foot but past the threshold beside it, the traveller is off the route, not there.
  @Test("a traveller off the route at its end has not arrived")
  func offAtTheEnd() throws {
    let engine = try navigating()

    try engine.setPosition(north(60, atLongitude: 0.02))

    #expect(engine.state.status == .offRoute)
    #expect(engine.state.progress?.toArrival.distance == 0)
  }

  /// N12, progress off the route: read on every position while a route is held, so a far-off
  /// position can push it ahead for good, since progress never moves back.
  @Test("progress is read on every position while a route is held")
  func progressOffTheRoute() throws {
    let engine = try navigating()

    try engine.setPosition(north(200, atLongitude: 0.019))
    let pushed = engine.state.progress?.along ?? .nan
    #expect(engine.state.status == .offRoute)
    #expect(isClose(pushed, length * 0.95, within: 1))

    engine.reroute("from here")
    try engine.setPosition(north(300, atLongitude: 0.019))
    #expect(engine.state.status == .rerouting)
    #expect(isClose(engine.state.progress?.along ?? .nan, pushed, within: 1e-6))

    try engine.sent[engine.sent.count - 1].fail(Unreachable(reason: "no signal"))
    try engine.setPosition([0.005, 0])
    #expect(engine.state.status == .navigating)
    #expect(isClose(engine.state.progress?.along ?? .nan, pushed, within: 1e-6))
  }

  /// N12, the reroute: the host asks, through `reroute`, and nothing asks on its own.
  @Test("a new route is asked for by reroute alone, and only off the route")
  func rerouteAlone() throws {
    let engine = try navigating()

    engine.reroute("on the route")
    #expect(engine.sent.count == 1)

    try engine.setPosition(north(200, atLongitude: 0.01))
    try engine.setPosition(north(300, atLongitude: 0.01))
    #expect(engine.state.status == .offRoute)
    #expect(engine.sent.count == 1, "off the route, no request leaves on its own")

    engine.reroute("from here")
    engine.reroute("from here, again")
    #expect(engine.state.status == .rerouting)
    #expect(engine.sent.map(\.request) == ["summit", "from here"])

    try engine.sent[1].fail(Unreachable(reason: "no signal"))
    #expect(engine.state.status == .offRoute)
    #expect(engine.state.error?.kind == .routeFailed)
    #expect(engine.state.error?.cause as? Unreachable == Unreachable(reason: "no signal"))
    #expect(engine.state.route?.line == eastward.line)
    #expect(engine.sent.count == 2, "a failed reroute is not retried")

    engine.reroute("from here, once more")
    #expect(engine.sent.count == 3)
  }

  @Test("a new route that lands is followed, and the last position read on it")
  func newRouteLands() throws {
    let engine = try navigating()
    let from = north(200, atLongitude: 0.01)

    try engine.setPosition(from)
    engine.reroute("from here")
    try engine.setPosition(north(0, atLongitude: 0.01))
    #expect(engine.state.status == .rerouting, "a position moves nothing while it is awaited")

    let back = NavigationRoute(line: [north(200, atLongitude: 0.01), [0.02, 0]], duration: 600)
    try engine.setPosition(from)
    try engine.sent[1].answer(back)

    #expect(engine.state.status == .navigating)
    #expect(engine.state.route?.line == back.line)
    #expect(engine.state.progress?.along == 0)
    #expect(engine.state.error == nil)
  }

  /// What a renderer is told, and in what order: a route that lands with a position held is the
  /// route first, unread, then that position's reading on it.
  @Test("a route that lands is reported, then the position held is read on it")
  func routeThenReading() async throws {
    let engine = ScriptedNavigationEngine<String>()
    let seen = try await recorded(engine) {
      try engine.setPosition([0.005, 0])
      engine.start("summit")
      try engine.sent[0].answer(eastward)
    }

    #expect(seen.map(\.status) == [.idle, .routing, .navigating, .navigating])
    #expect(seen[2].progress == nil)
    #expect(isClose(seen[3].progress?.along ?? .nan, length / 4, within: 1e-6))
  }

  /// One state a command at most: a position that reaches the end is reported arrived, never on
  /// the route first, and one that moves nothing reports nothing.
  @Test("each command reports one state at most, and only a change")
  func oneStateACommand() async throws {
    let engine = try navigating()
    let seen = try await recorded(engine) {
      try engine.setPosition([0.005, 0])
      try engine.setPosition([0.005, 0])
      engine.reroute("on the route")
      try engine.setPosition([0.0204, 0])
      engine.stop()
      engine.stop()
    }

    #expect(seen.map(\.status) == [.navigating, .navigating, .arrived, .idle])
    #expect(seen[0].progress == nil)
    #expect(seen.last == .idle)
  }

  @Test("a reroute reports rerouting, then the new route, then its reading")
  func rerouteOrder() async throws {
    let engine = try navigating()
    try engine.setPosition(north(200, atLongitude: 0.01))
    let seen = try await recorded(engine) {
      engine.reroute("from here")
      try engine.sent[1].answer(
        NavigationRoute(line: [north(200, atLongitude: 0.01), [0.02, 0]], duration: 600))
    }

    #expect(seen.map(\.status) == [.offRoute, .rerouting, .navigating, .navigating])
    #expect(seen[0].route == seen[1].route)
    #expect(seen[0].progress == seen[1].progress)
    #expect(seen[2].progress == nil)
    #expect(seen[3].progress?.along == 0)
  }

  @Test("a position stated with no route is kept, and read on the route that lands next")
  func positionKept() throws {
    let engine = ScriptedNavigationEngine<String>()

    try engine.setPosition([0.005, 0])
    #expect(engine.state.progress == nil)
    engine.start("summit")
    try engine.sent[0].answer(eastward)

    #expect((engine.state.progress?.along ?? 0) > 0)
  }

  /// A host that reuses one fix for every position moves nothing the engine holds; a Swift array is
  /// a value, so this holds by construction, and the altitude is never read.
  @Test("a position is copied as it is stated")
  func positionCopied() throws {
    let engine = ScriptedNavigationEngine<String>()
    var fix: [Double] = [0.005, 0, 1_200]

    try engine.setPosition(fix)
    fix[0] = 0.015
    engine.start("summit")
    try engine.sent[0].answer(eastward)

    #expect(isClose(engine.state.progress?.along ?? .nan, length / 4, within: 1e-6))
  }

  @Test("a start made in flight is sent once the answer lands, and only the newest is followed")
  func startsInFlight() throws {
    let engine = ScriptedNavigationEngine<String>()

    engine.start("a")
    engine.start("b")
    engine.start("c")
    #expect(engine.sent.map(\.request) == ["a"])

    try engine.sent[0].answer(eastward)
    #expect(engine.state.status == .routing)
    #expect(engine.sent.map(\.request) == ["a", "c"])

    let newest = NavigationRoute(line: [[1, 1]])
    try engine.sent[1].answer(newest)
    #expect(engine.state.route?.line == newest.line)
  }

  @Test("a stop abandons what is in flight and drops its late answer")
  func stopAbandons() throws {
    let engine = ScriptedNavigationEngine<String>()

    engine.start("a")
    engine.stop()
    #expect(engine.sent[0].isAbandoned)
    #expect(engine.state.status == .idle)

    engine.start("b")
    #expect(engine.sent.count == 2, "the next start is sent at once")

    try engine.sent[0].answer(eastward)
    #expect(engine.state.status == .routing)
    #expect(engine.state.route == nil)
  }

  @Test("a first route that fails leaves nothing to follow")
  func firstRouteFails() throws {
    let engine = ScriptedNavigationEngine<String>()

    engine.start("summit")
    try engine.sent[0].fail(Unreachable(reason: "offline"))

    #expect(engine.state.status == .failed)
    #expect(engine.state.route == nil)
    #expect(engine.state.progress == nil)
    #expect(engine.state.error?.kind == .routeFailed)
    #expect(engine.state.error?.cause as? Unreachable == Unreachable(reason: "offline"))
  }

  @Test("a route whose line holds no vertex fails")
  func emptyRoute() throws {
    let engine = ScriptedNavigationEngine<String>()

    engine.start("summit")
    try engine.sent[0].answer(NavigationRoute(line: []))

    #expect(engine.state.status == .failed)
    #expect(engine.state.route == nil)
    #expect(engine.state.error?.kind == .emptyRoute)
    #expect(engine.state.error?.cause == nil)
  }

  /// A failure is identified where the engine records it, an empty route as much as a failed
  /// request (`sdk/SPEC.md` §14): two recorded apart are two, so a state holding one never equals
  /// a state holding the other.
  @Test("two empty routes recorded apart are two failures")
  func emptyRoutesApart() throws {
    let engine = ScriptedNavigationEngine<String>()

    engine.start("summit")
    try engine.sent[0].answer(NavigationRoute(line: []))
    let first = engine.state
    let copy = first
    engine.start("summit")
    try engine.sent[1].answer(NavigationRoute(line: []))
    let second = engine.state

    #expect(first.error?.kind == .emptyRoute)
    #expect(second.error?.kind == .emptyRoute)
    #expect(first.status == second.status && first.route == second.route)
    #expect(copy == first, "one failure and its copies are one")
    #expect(first.error != second.error)
    #expect(first != second, "a state holding one failure never equals one holding another")
  }

  /// The error is why the last request acted on failed: kept through positions and a reroute, and
  /// cleared by a start and by a route that lands.
  @Test("the error stands until a start or a route that lands")
  func errorStands() throws {
    let engine = try navigating()
    try engine.setPosition(north(200, atLongitude: 0.01))
    engine.reroute("from here")
    try engine.sent[1].fail(Unreachable(reason: "no signal"))

    try engine.setPosition(north(0, atLongitude: 0.01))
    #expect(engine.state.status == .navigating)
    #expect(engine.state.error?.kind == .routeFailed)

    engine.start("elsewhere")
    #expect(engine.state.error == nil)

    try engine.sent[2].fail(Unreachable(reason: "offline"))
    engine.start("again")
    try engine.sent[3].answer(eastward)
    #expect(engine.state.error == nil)
  }

  /// As `sdk-typescript`'s engine does, a stop forgets the route and keeps the last position
  /// stated.
  @Test("a stop keeps the last position for the next route")
  func stopKeepsPosition() throws {
    let engine = try navigating()

    try engine.setPosition([0.005, 0])
    engine.stop()
    engine.start("again")
    try engine.sent[1].answer(eastward)

    #expect(isClose(engine.state.progress?.along ?? .nan, length / 4, within: 1e-6))
  }

  @Test("a position that names no place is refused by its value")
  func positionRefused() throws {
    let engine = try navigating()

    let refusal = #expect(throws: PositionError.self) { try engine.setPosition([.nan, 45]) }
    #expect(refusal?.description.contains("[nan, 45.0]") == true)
    #expect(throws: PositionError.self) { try engine.setPosition([6]) }
    #expect(engine.state.progress == nil)
  }

  @Test("after a close every command does nothing, and a late answer is dropped")
  func afterClose() throws {
    let engine = ScriptedNavigationEngine<String>()

    engine.start("summit")
    engine.close()
    #expect(engine.sent[0].isAbandoned)

    try engine.sent[0].answer(eastward)
    engine.start("again")
    try engine.setPosition([.nan, 0])
    engine.close()

    #expect(engine.state.status == .routing)
    #expect(engine.sent.count == 1)
  }

  /// Swift's two readers of a state: Observation, which a SwiftUI view reads through, and a
  /// stream of its own per reader.
  @Test("a change is observed, and a command that changes nothing is not")
  func observed() throws {
    let engine = try navigating()
    try engine.setPosition([0.005, 0])
    let changed = Locked(false)
    withObservationTracking {
      _ = engine.state
    } onChange: {
      changed.withLock { $0 = true }
    }

    try engine.setPosition([0.005, 0])
    engine.reroute("on the route")
    #expect(!changed.value)

    try engine.setPosition([0.0204, 0])
    #expect(changed.value)
  }

  @Test("every reader is handed every state, and a stream taken after a close holds the last")
  func readers() async throws {
    let engine = ScriptedNavigationEngine<String>()
    let first = engine.subscribe()
    let second = engine.subscribe()
    engine.start("summit")
    try engine.sent[0].answer(eastward)
    engine.close()

    var seen: [[NavigationStatus]] = []
    for stream in [first, second, engine.subscribe()] {
      var statuses: [NavigationStatus] = []
      for await state in stream {
        statuses.append(state.status)
      }
      seen.append(statuses)
    }
    #expect(
      seen == [[.idle, .routing, .navigating], [.idle, .routing, .navigating], [.navigating]])
  }
}
