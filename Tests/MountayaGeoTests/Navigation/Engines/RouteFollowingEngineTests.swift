import Testing

@testable import MountayaGeo

/// The measurements a followed route's line may cost: one, when the route is followed, which every
/// position read along it then stands on.
///
/// A measurement is a haversine per vertex of the whole route, and a position arrives on every fix,
/// so a route measured per fix pays for its whole length again on the path every fix takes. Before
/// this budget, a route with no steps of its own was measured twice as it was followed, once for its
/// departure's length and once for its measure.
private let routeMeasureBudget = 1

@Suite("RouteFollowingEngine")
@MainActor
struct RouteFollowingEngineTests {
  private struct Unreachable: Error {}

  /// Sent is a request the machine sent, and the ticket it left under.
  private struct Sent: Equatable {
    let request: String
    let ticket: Int
  }

  /// Recorder keeps what the machine sends and abandons.
  @MainActor
  private final class Recorder {
    var sent: [Sent] = []
    var abandoned: [Int] = []
  }

  private let route = NavigationRoute(line: [[0, 0], [0.01, 0]], duration: 600)

  private func machine() -> (RouteFollowingEngine<String>, Recorder) {
    let recorder = Recorder()
    let engine = RouteFollowingEngine<String>(
      send: { recorder.sent.append(Sent(request: $0, ticket: $1)) },
      abandon: { recorder.abandoned.append($0) })
    return (engine, recorder)
  }

  /// A ticket is the count of requests sent with it, so an answer names the request it answers.
  @Test("each request leaves under the next ticket")
  func tickets() throws {
    let (engine, recorder) = machine()

    engine.start("a")
    engine.answered(ticket: 1, with: .route(route))
    try engine.setPosition([0.005, 0.01])
    engine.reroute("b")

    #expect(recorder.sent == [Sent(request: "a", ticket: 1), Sent(request: "b", ticket: 2)])
  }

  @Test("answering the request in flight sends the one waiting instead of acting on it")
  func waitingSent() {
    let (engine, recorder) = machine()

    engine.start("a")
    engine.start("b")
    engine.answered(ticket: 1, with: .route(route))

    #expect(recorder.sent == [Sent(request: "a", ticket: 1), Sent(request: "b", ticket: 2)])
    #expect(engine.state.status == .routing)

    engine.answered(ticket: 2, with: .route(route))
    #expect(engine.state.status == .navigating)
  }

  @Test("a stop abandons the ticket in flight, and nothing when none is")
  func stopAbandons() {
    let (engine, recorder) = machine()

    engine.stop()
    #expect(recorder.abandoned.isEmpty)

    engine.start("a")
    engine.start("b")
    engine.stop()
    #expect(recorder.abandoned == [1])

    engine.answered(ticket: 1, with: .route(route))
    #expect(engine.state.status == .idle)
    #expect(recorder.sent == [Sent(request: "a", ticket: 1)], "the request that waited was dropped")
  }

  @Test("an answer to a ticket nobody awaits is dropped")
  func unawaited() {
    let (engine, _) = machine()

    engine.start("a")
    engine.answered(ticket: 7, with: .failure(Unreachable()))
    engine.answered(ticket: 0, with: .route(route))

    #expect(engine.state.status == .routing)
  }

  /// north is the position `meters` north of the equator at `longitude`.
  private func north(_ meters: Double, atLongitude longitude: Double) -> [Double] {
    [longitude, meters / metersPerDegreeMeanSphere]
  }

  @Test("hot-path budget route-measure: sixty fixes and a reroute measure each line followed once")
  func routeMeasure() throws {
    let (engine, _) = machine()
    let probe = MeasureProbe()
    // Two legs east along the equator, with no steps of their own, so the route is followed by a
    // departure and an arrival.
    let eastward = NavigationRoute(line: [[0, 0], [0.01, 0], [0.02, 0]], duration: 1_200)
    let leftAt = north(200, atLongitude: 0.012)
    let back = NavigationRoute(line: [leftAt, north(200, atLongitude: 0.02)], duration: 600)
    var alongs: [Double] = []
    var states: [NavigationStatus] = []

    try MeasureProbe.$current.withValue(probe) {
      engine.start("out")
      engine.answered(ticket: 1, with: .route(eastward))
      // Thirty fixes along the way out, 5 m north of it, the traveller's progress moving on each.
      for fix in 1...30 {
        try engine.setPosition(north(5, atLongitude: 0.01 * Double(fix) / 30))
        alongs.append(engine.state.progress?.along ?? .nan)
      }
      states.append(engine.state.status)
      // Off the route, a new one asked for and followed, then thirty fixes along it to its end.
      try engine.setPosition(leftAt)
      states.append(engine.state.status)
      engine.reroute("from here")
      engine.answered(ticket: 2, with: .route(back))
      for fix in 1...30 {
        try engine.setPosition(north(200, atLongitude: 0.012 + 0.008 * Double(fix) / 30))
      }
      states.append(engine.state.status)
    }

    // The work happened: each fix was read along the route it followed, and the second route was
    // followed to its end.
    #expect(zip(alongs, alongs.dropFirst()).allSatisfy { $0 < $1 }, "\(alongs)")
    #expect(states == [.navigating, .offRoute, .arrived])
    #expect(engine.state.route?.line == back.line)
    // Each line followed, measured at most once, and at least once: nothing else is measured, the
    // line already left least of all.
    let measured = (
      eastward: probe.lines.filter { $0 == eastward.line }.count,
      back: probe.lines.filter { $0 == back.line }.count
    )
    #expect(
      (1...routeMeasureBudget).contains(measured.eastward)
        && (1...routeMeasureBudget).contains(measured.back),
      "measured \(measured)")
    #expect(probe.lines.count == measured.eastward + measured.back, "\(probe.lines)")
  }

  @Test("a close abandons the request in flight once, and ignores its answer")
  func closeAbandonsOnce() {
    let (engine, recorder) = machine()

    engine.start("a")
    engine.close()
    engine.close()
    engine.answered(ticket: 1, with: .route(route))

    #expect(recorder.abandoned == [1])
    #expect(engine.state.status == .routing)
  }

  /// settled reads a stream until a state of `status` comes, and answers it, or nil where the
  /// stream ends first.
  private func settled(
    _ states: AsyncStream<NavigationState>, at status: NavigationStatus
  ) async -> NavigationState? {
    for await state in states where state.status == status {
      return state
    }
    return nil
  }

  /// journey drives a machine through a route, a position on it, one off it, a stop and a close,
  /// hands `after` the state each command leaves, and answers every state it committed, in order,
  /// the first one held included.
  private func journey(
    _ engine: RouteFollowingEngine<String>, after: (NavigationState) -> Void = { _ in }
  ) throws -> [NavigationState] {
    var committed = [engine.state]
    func note() {
      after(engine.state)
      if committed.last != engine.state { committed.append(engine.state) }
    }
    engine.start("a")
    note()
    engine.answered(ticket: 1, with: .route(route))
    note()
    try engine.setPosition([0.005, 0])
    note()
    try engine.setPosition([0.005, 0.01])
    note()
    engine.stop()
    note()
    engine.close()
    return committed
  }

  /// Each stream promises its own reader every state in order; the order two readers read one
  /// state in is the main actor's, which promises none, so nothing here reads across readers.
  @Test("each stream is handed every state in order, whatever order its reader reads in")
  func everyStateInOrder() async throws {
    let (engine, _) = machine()
    let streams = (0..<8).map { _ in engine.subscribe() }

    let committed = try journey(engine)

    #expect(
      committed.map(\.status) == [.idle, .routing, .navigating, .navigating, .offRoute, .idle])
    for states in streams.reversed() {
      var read: [NavigationState] = []
      for await state in states { read.append(state) }
      #expect(read == committed)
    }
  }

  @Test("onChange is told each state inline, in order, before the command that made it returns")
  func onChangeInline() throws {
    var told: [NavigationState] = []
    let engine = RouteFollowingEngine<String>(
      send: { _, _ in }, abandon: { _ in }, onChange: { told.append($0) })

    let committed = try journey(engine) { state in
      #expect(told.last == state, "the state a command left was told before it returned")
    }

    #expect(told == Array(committed.dropFirst()))
  }

  /// A close ends every stream, so a close made in `onChange` leaves the state it was told in no
  /// stream: it reaches `onChange` before it reaches any.
  @Test("onChange is told each state before any stream is handed it")
  func onChangeBeforeStreams() async {
    weak var owner: RouteFollowingEngine<String>?
    let engine = RouteFollowingEngine<String>(
      send: { _, _ in }, abandon: { _ in },
      onChange: { state in if state.status == .routing { owner?.close() } })
    owner = engine
    let streams = (0..<4).map { _ in engine.subscribe() }

    engine.start("a")

    #expect(engine.state.status == .routing)
    for states in streams {
      var read: [NavigationStatus] = []
      for await state in states { read.append(state.status) }
      #expect(read == [.idle], "the state onChange closed on reached no stream")
    }
  }

  @Test(
    "a command onChange makes is handed on after the state it was told, to it and every stream")
  func onChangeCommands() async {
    weak var owner: RouteFollowingEngine<String>?
    var told: [NavigationStatus] = []
    var late: AsyncStream<NavigationState>?
    let engine = RouteFollowingEngine<String>(
      send: { _, _ in }, abandon: { _ in },
      onChange: { state in
        told.append(state.status)
        guard state.status == .routing, late == nil else { return }
        // A stream returned while a state is handed on starts at the newest, and is handed none
        // before it.
        owner?.stop()
        late = owner?.subscribe()
      })
    owner = engine
    let early = engine.subscribe()

    engine.start("a")
    engine.close()

    #expect(told == [.routing, .idle])
    var fromEarly: [NavigationStatus] = []
    for await state in early { fromEarly.append(state.status) }
    #expect(fromEarly == [.idle, .routing, .idle])
    var fromLate: [NavigationStatus] = []
    if let late {
      for await state in late { fromLate.append(state.status) }
    }
    #expect(fromLate == [.idle])
  }

  /// A route that lands while a position is held is followed, then that position is read on it, in
  /// one turn: a close made as the route is told ends that turn, and the reading is never made.
  @Test("a close onChange makes ends the command it was told from, and nothing after it is told")
  func onChangeCloses() throws {
    weak var owner: RouteFollowingEngine<String>?
    var told: [NavigationStatus] = []
    let engine = RouteFollowingEngine<String>(
      send: { _, _ in }, abandon: { _ in },
      onChange: { state in
        told.append(state.status)
        if state.status == .navigating { owner?.close() }
      })
    owner = engine

    engine.start("a")
    try engine.setPosition([0.005, 0])
    engine.answered(ticket: 1, with: .route(route))

    #expect(told == [.routing, .navigating], "the reading on the route was told to nobody")
    #expect(engine.state.status == .navigating)
    #expect(engine.state.progress == nil, "a closed engine's state stays as the close left it")
  }

  /// The request leaves before the state that asks for it is told, so a stop told that state
  /// abandons it, and the next start's request leaves at once rather than wait behind it.
  @Test("a stop onChange makes on routing abandons the request that state asked for")
  func onChangeStopAbandonsTheRequest() {
    weak var owner: RouteFollowingEngine<String>?
    let recorder = Recorder()
    var stops = 1
    let engine = RouteFollowingEngine<String>(
      send: { recorder.sent.append(Sent(request: $0, ticket: $1)) },
      abandon: { recorder.abandoned.append($0) },
      onChange: { state in
        guard state.status == .routing, stops > 0 else { return }
        stops -= 1
        owner?.stop()
      })
    owner = engine

    engine.start("a")
    #expect(engine.state == .idle)
    #expect(recorder.sent == [Sent(request: "a", ticket: 1)])
    #expect(recorder.abandoned == [1], "the request the stop was told of is abandoned")

    engine.start("b")
    #expect(
      recorder.sent == [Sent(request: "a", ticket: 1), Sent(request: "b", ticket: 2)],
      "nothing is left in flight for the next request to wait behind")
    engine.answered(ticket: 2, with: .route(route))
    #expect(engine.state.status == .navigating)
  }

  @Test("a close onChange makes on rerouting abandons the request that state asked for")
  func onChangeCloseAbandonsTheReroute() throws {
    weak var owner: RouteFollowingEngine<String>?
    let recorder = Recorder()
    let engine = RouteFollowingEngine<String>(
      send: { recorder.sent.append(Sent(request: $0, ticket: $1)) },
      abandon: { recorder.abandoned.append($0) },
      onChange: { state in if state.status == .rerouting { owner?.close() } })
    owner = engine

    engine.start("a")
    engine.answered(ticket: 1, with: .route(route))
    try engine.setPosition([0.005, 0.01])
    engine.reroute("b")

    #expect(recorder.sent == [Sent(request: "a", ticket: 1), Sent(request: "b", ticket: 2)])
    #expect(recorder.abandoned == [2])
    engine.answered(ticket: 2, with: .route(route))
    #expect(engine.state.status == .rerouting, "a closed engine acts on no answer")
  }

  @Test("built over a route source, it asks the source and follows the route it answers")
  func routeSource() async throws {
    let (asked, ask) = AsyncStream.makeStream(of: String.self)
    let line = route.line
    let engine = RouteFollowingEngine<String> { request in
      ask.yield(request)
      return NavigationRoute(line: line, duration: 600)
    }
    let states = engine.subscribe()

    engine.start("summit")
    try engine.setPosition([0.005, 0])

    #expect(engine.state.status == .routing, "a command has its effect, and the answer lands later")
    let navigating = await settled(states, at: .navigating)
    #expect(navigating?.route?.line == line)
    #expect(engine.state.progress?.along ?? 0 > 0, "the position held is read on the route")
    var requests = asked.makeAsyncIterator()
    #expect(await requests.next() == "summit")
    engine.close()
  }

  @Test("built over a route source, a failure it throws is the navigation's error")
  func routeSourceFails() async throws {
    let engine = RouteFollowingEngine<String> { _ in throw Unreachable() }
    let states = engine.subscribe()

    engine.start("summit")

    let failed = try #require(await settled(states, at: .failed))
    #expect(failed.error?.kind == .routeFailed)
    #expect(failed.error?.cause is Unreachable)
    engine.close()
  }

  /// A cancellation is a failure where the task asking was not cancelled: a source that times its
  /// own call out, as `sdk-kotlin`'s `withTimeout` does.
  @Test("built over a route source, a cancellation it throws while still asked is its failure")
  func routeSourceThrowsCancellation() async throws {
    let engine = RouteFollowingEngine<String> { _ in throw CancellationError() }
    let states = engine.subscribe()

    engine.start("summit")

    let failed = try #require(await settled(states, at: .failed))
    #expect(failed.error?.kind == .routeFailed)
    #expect(failed.error?.cause is CancellationError)
    engine.close()
  }

  /// `sdk-kotlin` lands such an answer before the start returns on an immediate dispatcher; here a
  /// task asks, so it lands in the main actor's next turn, never inside the command.
  @Test("built over a source that answers at once, the route lands after the start returns")
  func routeSourceAnswersAtOnce() async throws {
    let line = route.line
    let engine = RouteFollowingEngine<String> { _ in NavigationRoute(line: line, duration: 600) }
    let states = engine.subscribe()

    try engine.setPosition([0.005, 0])
    engine.start("summit")
    #expect(engine.state.status == .routing)

    _ = await settled(states, at: .navigating)
    #expect(engine.state.status == .navigating)
    #expect(engine.state.progress?.along ?? 0 > 0, "the position held is read on the route")

    engine.start("summit")
    engine.stop()
    #expect(engine.state == .idle)
    for _ in 0..<8 {
      await Task.yield()
    }
    #expect(engine.state == .idle, "the answer to the request a stop abandoned is dropped")
    engine.close()
  }

  @Test("built over a route source, a stop cancels the task asking, and drops its answer")
  func routeSourceCancelled() async throws {
    let (asked, ask) = AsyncStream.makeStream(of: String.self)
    let (outcomes, report) = AsyncStream.makeStream(of: Bool.self)
    let line = route.line
    let engine = RouteFollowingEngine<String> { request in
      ask.yield(request)
      do {
        try await Task.sleep(for: .seconds(3_600))
        report.yield(false)
      } catch {
        report.yield(true)
      }
      // A source that answers anyway: the answer is dropped.
      return NavigationRoute(line: line)
    }

    engine.start("summit")
    // The source is asked in the task's own turn; the stop comes once it is.
    var requests = asked.makeAsyncIterator()
    #expect(await requests.next() == "summit")
    engine.stop()

    var cancelled = outcomes.makeAsyncIterator()
    #expect(await cancelled.next() == true)
    // The task's own turn comes after the report; one more turn of the main actor lets it end.
    await Task.yield()
    #expect(engine.state == .idle)
  }

  @Test("built over a route source, a close cancels the request in flight")
  func routeSourceClosed() async throws {
    let (asked, ask) = AsyncStream.makeStream(of: String.self)
    let (outcomes, report) = AsyncStream.makeStream(of: Bool.self)
    let engine = RouteFollowingEngine<String> { request in
      ask.yield(request)
      do {
        try await Task.sleep(for: .seconds(3_600))
        report.yield(false)
      } catch {
        report.yield(true)
        throw error
      }
      throw Unreachable()
    }

    engine.start("summit")
    var requests = asked.makeAsyncIterator()
    #expect(await requests.next() == "summit")
    engine.close()

    var cancelled = outcomes.makeAsyncIterator()
    #expect(await cancelled.next() == true)
    await Task.yield()
    #expect(engine.state.status == .routing, "after a close the state stays as it was")
  }

  /// The request a stop abandons in the turn that sent it has a task that never asks: the next
  /// request is the first the source hears of.
  @Test("built over a route source, a request abandoned before its task asks is never asked")
  func routeSourceNeverAsked() async throws {
    let asked = Locked<[String]>([])
    let (landed, land) = AsyncStream.makeStream(of: String.self)
    let line = route.line
    let engine = RouteFollowingEngine<String> { request in
      asked.withLock { $0.append(request) }
      land.yield(request)
      return NavigationRoute(line: line)
    }

    engine.start("abandoned")
    engine.stop()
    engine.start("asked")

    var requests = landed.makeAsyncIterator()
    #expect(await requests.next() == "asked")
    #expect(asked.value == ["asked"], "the request the stop abandoned never reached the source")
    engine.close()
  }

  @Test("built over a route source, a stop onChange makes on routing leaves the source unasked")
  func routeSourceUnaskedAfterAStopOnChange() async throws {
    let asked = Locked<[String]>([])
    let (landed, land) = AsyncStream.makeStream(of: String.self)
    let line = route.line
    weak var owner: RouteFollowingEngine<String>?
    var stops = 1
    let engine = RouteFollowingEngine<String>(
      route: { request in
        asked.withLock { $0.append(request) }
        land.yield(request)
        return NavigationRoute(line: line)
      },
      onChange: { state in
        guard state.status == .routing, stops > 0 else { return }
        stops -= 1
        owner?.stop()
      })
    owner = engine
    let states = engine.subscribe()

    engine.start("abandoned")
    #expect(engine.state == .idle)
    engine.start("asked")

    var requests = landed.makeAsyncIterator()
    #expect(await requests.next() == "asked")
    #expect(
      asked.value == ["asked"], "the stop was told of the routing state after its request left")
    #expect(await settled(states, at: .navigating) != nil, "the next request lands at once")
    engine.close()
  }
}
