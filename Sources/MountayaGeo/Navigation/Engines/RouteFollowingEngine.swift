import Observation

/// RouteFollowingEngine is the whole of following a route over the contract's rules: the route
/// requests, the status, the progress and the arrival, and the state a renderer draws. Every
/// engine is this machine with a way to send a request: the scripted one hands each to a test, and
/// one built with `init(route:)` to the host's route source, in a task of its own.
///
/// Every decision it makes is a rule of the contract's, read where it is stated: which request is
/// sent and which answer is acted on (`routeRequestsAfter(_:on:)`), the status each event moves it
/// to (`navigationStatusAfter(_:on:)`), the steps a route is followed by (`followedRouteOf(_:)`),
/// where the traveller stands and what is left (`navigationProgressAt(_:position:previous:)`), and
/// whether they are off the route (`isOffRoute(_:)` of the distance `metersToRoute(_:lines:)`
/// measures to the route's line, as `isOffRouteAt(_:lines:)` answers), the last two read in one
/// pass over the line. It holds the state those rules are handed and nothing they do not decide.
/// Three edges the contract leaves open are answered as
/// `sdk-typescript`'s engine answers them: the arrival is raised where the traveller is on the
/// route and their progress stands at its end, progress is read on every position while a route
/// is held, and a new route is asked for by `reroute(_:)` alone.
///
/// It is published as the building block every engine stands on, `MountayaNavigation`'s among them,
/// and it is a `NavigationEngine` of its own: built over a route source, it follows a route on any
/// platform the package builds on, with positions from wherever the host reads them, which it
/// hands to `setPosition(_:)`.
///
/// ```swift
/// let navigation = RouteFollowingEngine<[[Double]]> { waypoints in
///   try await routeFromYourSource(waypoints)
/// }
/// navigation.start([[6.8652, 45.9237], [6.9271, 45.9682]])
/// try navigation.setPosition([6.8655, 45.9239])
/// ```
///
/// It is bound to the main actor, as every engine is, and holds no lock: each command runs to its
/// end before the next, and a route request's answer is acted on in the main actor's next turn
/// after it lands. An engine built over it that must act on each state before any reader sees it
/// is told each one by `onChange`, inline, before any stream is handed it.
@MainActor
@Observable
public final class RouteFollowingEngine<Request: Sendable>: NavigationEngine {
  /// Answer is a route request's answer: the route, or what its source failed with.
  enum Answer {
    /// route is the route the source answered.
    case route(NavigationRoute)
    /// failure is what the source threw.
    case failure(any Error)
  }

  /// state is the navigation as it stands, `NavigationState.idle` before the first command.
  public var state: NavigationState { held }

  /// held is the state the machine holds, which an observer of `state` is told of.
  private var held = NavigationState.idle

  /// send sends a request under the ticket its answer is to name, through `answered(ticket:with:)`.
  @ObservationIgnored private let send: (Request, Int) -> Void
  /// abandon abandons the request sent under a ticket: a stop or a close no longer awaits it, and
  /// an answer to it is dropped whatever it is.
  @ObservationIgnored private let abandon: (Int) -> Void
  /// requests is the route requests, as `routeRequestsAfter(_:on:)` leaves them.
  @ObservationIgnored private var requests = RouteRequests<Request>.atRest
  /// position is the last position the host stated, read again against a route that lands after
  /// it.
  @ObservationIgnored private var position: [Double]?
  @ObservationIgnored private var closed = false
  /// onChange is told each state the machine commits, inline, before any stream is handed it.
  @ObservationIgnored private let onChange: (@MainActor (NavigationState) -> Void)?
  /// Subscriber is a stream `subscribe()` returned, and the count of states committed when it
  /// was, which it was handed as its first state.
  private struct Subscriber {
    let since: Int
    let continuation: AsyncStream<NavigationState>.Continuation
  }
  /// subscribers is every stream `subscribe()` returned that has not ended, by its number.
  @ObservationIgnored private var subscribers: [Int: Subscriber] = [:]
  @ObservationIgnored private var nextSubscriber = 0
  /// committed is the count of states the machine committed, each one's number in its order.
  @ObservationIgnored private var committed = 0
  /// pending is every state committed and not yet handed on, by its number, in order: a command
  /// `onChange` makes commits while a state is being handed on, and is handed on after it.
  @ObservationIgnored private var pending: [(number: Int, state: NavigationState)] = []
  @ObservationIgnored private var handing = false
  /// flights is the task asking a route source for each request in flight, by its ticket.
  @ObservationIgnored private var flights: [Int: Task<Void, Never>] = [:]

  /// Creates a machine that sends each request through `send`, abandons one through `abandon`,
  /// and tells `onChange` each state it commits.
  init(
    send: @escaping (Request, Int) -> Void, abandon: @escaping (Int) -> Void,
    onChange: (@MainActor (NavigationState) -> Void)? = nil
  ) {
    self.send = send
    self.abandon = abandon
    self.onChange = onChange
  }

  /// Creates an engine that is idle, and asks `route` for each route it follows, one request at a
  /// time, in a task of its own: a stop or a close cancels the task asking for the route it
  /// abandons, and drops its answer.
  ///
  /// `onChange`, where given, is told each state that differs from the one before it, inline and
  /// in order, before any stream `subscribe()` returned is handed it, a route that lands in a turn
  /// of its own as much as a command's state. It is for an engine built over this one that keeps
  /// something of its own to each state, as a navigation's guidance keeps to the route followed
  /// and the prompts said along it. A command it makes on this engine has its effect at once, and
  /// its state is handed on after the one `onChange` was told, to `onChange` and to every stream
  /// alike. A request is sent before the state that asks for it is told, so a stop or a close it
  /// makes on `routing` or `rerouting` abandons that request, and a request abandoned before its
  /// task asks is never asked of `route`.
  public convenience init(
    route: @escaping NavigationRouteSource<Request>,
    onChange: (@MainActor (NavigationState) -> Void)? = nil
  ) {
    weak var owner: RouteFollowingEngine<Request>?
    self.init(
      send: { request, ticket in owner?.ask(route, for: request, ticket: ticket) },
      abandon: { ticket in owner?.flights.removeValue(forKey: ticket)?.cancel() },
      onChange: onChange
    )
    owner = self
  }

  deinit {
    // A machine let go of ends its streams, so no reader waits on a state that never comes, and
    // cancels the route request it has in flight, which nobody awaits any more.
    for subscriber in subscribers.values {
      subscriber.continuation.finish()
    }
    for flight in flights.values {
      flight.cancel()
    }
  }

  /// subscribe returns a stream that yields the state as it is now, then every state that differs
  /// from the one before it, in order and with nothing dropped, for as long as the stream is held.
  /// It ends at `close()`.
  ///
  /// Each stream is its own reader's, and promises that reader every state in order. It promises
  /// nothing about the order in which two readers read one state, which is the order the main
  /// actor resumes their tasks in and is not promised either: a reader that must act on a state
  /// before any other reader sees it is an engine built with `onChange`.
  public func subscribe() -> AsyncStream<NavigationState> {
    let (stream, continuation) = AsyncStream.makeStream(
      of: NavigationState.self, bufferingPolicy: .unbounded)
    continuation.yield(state)
    if closed {
      continuation.finish()
      return stream
    }
    let number = nextSubscriber
    nextSubscriber += 1
    // A stream whose reader is gone is dropped at the next state it is handed. One returned while
    // a state is being handed on was handed the newest already, so it is handed none before it.
    subscribers[number] = Subscriber(since: committed, continuation: continuation)
    return stream
  }

  /// start asks for a route to follow, and follows it once it lands.
  public func start(_ request: Request) {
    guard !closed else { return }
    // Asked before the state is committed, so a stop or a close `onChange` makes on that state
    // abandons this request rather than leave it in flight behind the stop.
    ask(request)
    commit(NavigationState(status: navigationStatusAfter(state.status, on: .start)))
  }

  /// reroute asks for a new route where the navigation is `off-route`, and does nothing in any
  /// other status.
  public func reroute(_ request: Request) {
    guard !closed else { return }
    let now = state
    let rerouting = navigationStatusAfter(now.status, on: .reroute)
    // The table moves the status only off the route, which is the one place a request is owed.
    if rerouting == now.status { return }
    // Asked before the state is committed, as a start's request is.
    ask(request)
    commit(
      NavigationState(status: rerouting, route: now.route, progress: now.progress, error: now.error)
    )
  }

  /// setPosition states where the traveller is and reads it against the route followed, or keeps
  /// it for the route that lands next. It throws a `PositionError` where the position names no
  /// place.
  public func setPosition(_ position: [Double]) throws(PositionError) {
    guard !closed else { return }
    guard namesPlace(position) else { throw PositionError(position: position) }
    // The two coordinates alone, so the altitude a host states is never read.
    let stated = [position[0], position[1]]
    self.position = stated
    read(stated)
  }

  /// stop ends the navigation, abandoning the request in flight and the one waiting.
  public func stop() {
    guard !closed else { return }
    cancel()
    commit(NavigationState(status: navigationStatusAfter(state.status, on: .stop)))
  }

  /// close abandons the route requests, ends every stream, and makes every later command do
  /// nothing.
  public func close() {
    guard !closed else { return }
    closed = true
    cancel()
    pending = []
    let ended = subscribers.values
    subscribers = [:]
    for subscriber in ended {
      subscriber.continuation.finish()
    }
  }

  /// answered acts on the answer to the request sent under `ticket`, where the route requests
  /// deliver it, and sends what they say to send in its place.
  func answered(ticket: Int, with answer: Answer) {
    guard !closed else { return }
    let outcome = routeRequestsAfter(requests, on: .answered(ticket: ticket))
    requests = outcome.state
    if let next = outcome.send {
      send(next.request, next.ticket)
      return
    }
    guard outcome.deliver else { return }
    switch answer {
    case .route(let route): receive(route)
    case .failure(let cause): fail(.routeFailed(cause))
    }
  }

  /// ask asks a route source for `request` in a task of its own, and hands its answer to
  /// `answered(ticket:with:)` unless the request was abandoned meanwhile.
  private func ask(
    _ source: @escaping NavigationRouteSource<Request>, for request: Request, ticket: Int
  ) {
    flights[ticket] = Task { [weak self] in
      // A request abandoned before its task ran is never asked of the source.
      guard !Task.isCancelled else { return }
      let answer: Answer
      do {
        answer = .route(try await source(request))
      } catch {
        answer = .failure(error)
      }
      // An abandoned request's task is cancelled, and its answer is dropped whatever it is.
      guard !Task.isCancelled, let self else { return }
      flights[ticket] = nil
      answered(ticket: ticket, with: answer)
    }
  }

  /// cancel drops the waiting request and abandons the one in flight.
  private func cancel() {
    let inFlight = requests.inFlight
    requests = routeRequestsAfter(requests, on: .cancelled).state
    if let inFlight { abandon(inFlight) }
  }

  /// ask tells the route requests a request was made, and sends what they say to send.
  private func ask(_ request: Request) {
    let outcome = routeRequestsAfter(requests, on: .made(request))
    requests = outcome.state
    if let next = outcome.send { send(next.request, next.ticket) }
  }

  /// receive follows a route that landed, where the status table says it was awaited, and reads
  /// the last position against it at once.
  private func receive(_ route: NavigationRoute) {
    let now = state
    let navigating = navigationStatusAfter(now.status, on: .routeReceived)
    // An answer the navigation is not awaiting moves nothing.
    if navigating == now.status { return }
    guard let followed = followedRouteOf(route) else {
      fail(.emptyRoute())
      return
    }
    commit(NavigationState(status: navigating, route: followed))
    if let position { read(position) }
  }

  /// fail records a route request that failed, where the status table says it was awaited.
  private func fail(_ error: NavigationError) {
    let now = state
    let failed = navigationStatusAfter(now.status, on: .routeFailed)
    // An answer the navigation is not awaiting moves nothing.
    if failed == now.status { return }
    commit(NavigationState(status: failed, route: now.route, progress: now.progress, error: error))
  }

  /// read reads a position against the route followed, in one pass over its line: the progress
  /// from the last one, whether the traveller is off the route, and, on it, whether their progress
  /// stands at its end.
  private func read(_ position: [Double]) {
    let now = state
    guard let route = now.route else { return }
    let reading = navigationReadingAt(
      route, position: position, previous: now.progress?.along ?? 0)
    let off = isOffRoute(reading.metersToRoute)
    let placed = navigationStatusAfter(now.status, on: off ? .offRoute : .onRoute)
    let next =
      !off && reading.progress.toArrival.distance == 0
      ? navigationStatusAfter(placed, on: .arrived) : placed
    commit(
      NavigationState(status: next, route: route, progress: reading.progress, error: now.error))
  }

  /// commit publishes a state, where it differs from the one held: to an observer of `state`, then
  /// to `onChange`, then to every stream `subscribe()` returned.
  private func commit(_ next: NavigationState) {
    // A close `onChange` makes ends the command it was told from too: what that command would
    // still commit, the reading of a position held on a route that lands among it, is no state of
    // a closed engine.
    guard !closed, next != held else { return }
    held = next
    committed += 1
    pending.append((number: committed, state: next))
    // A state committed while another is handed on, by a command `onChange` makes, waits for it,
    // so `onChange` and every stream are handed the states in the order they were committed.
    guard !handing else { return }
    handing = true
    defer { handing = false }
    while !pending.isEmpty {
      let (number, state) = pending.removeFirst()
      onChange?(state)
      // In the order the streams were returned, never a dictionary's own order, which differs
      // from one process to the next, so a run hands its streams their states alike.
      for key in subscribers.keys.sorted() {
        guard let subscriber = subscribers[key], number > subscriber.since else { continue }
        if case .terminated = subscriber.continuation.yield(state) {
          subscribers[key] = nil
        }
      }
    }
  }
}
