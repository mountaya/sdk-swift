import Observation

/// ScriptedNavigationEngine is a `NavigationEngine` for an app's own unit tests: its route
/// requests are answered by the test, when the test says and as it says, and everything else is
/// the contract's.
///
/// It follows a route exactly as every engine does, over the same rules, so a state it reports is
/// one a navigation reports: the status the contract's table moves it to, the progress and the
/// instruction a position reads, the arrival. It links no navigation library and starts no task,
/// so it runs on every host the package builds on, and each command has its effect before it
/// returns: `state` after a command is the state it left.
///
/// Each request it sends is in `sent`, in the order they left, and the test answers one with a
/// route or a failure. At most one is in flight, as the contract says: a start made meanwhile
/// waits and is sent once the answer lands, and a stop or a close abandons the request in flight,
/// whose answer is then dropped.
///
/// ```swift
/// let navigation = ScriptedNavigationEngine<String>()
/// navigation.start("summit")
/// try navigation.sent[0].answer(NavigationRoute(line: [[0, 0], [0.01, 0]], duration: 600))
/// try navigation.setPosition([0.005, 0])
/// // navigation.state.status is .navigating
/// ```
///
/// It is bound to the main actor, as every engine is, so a test of it is too. `Request` is what the
/// app asks a route for, kept as it was made in each `ScriptedRouteRequest`.
@MainActor
@Observable
public final class ScriptedNavigationEngine<Request: Sendable>: NavigationEngine {
  @ObservationIgnored private let following: RouteFollowingEngine<Request>
  private var requests: [ScriptedRouteRequest<Request>] = []

  /// Creates an engine that is idle and has sent nothing.
  public init() {
    weak var owner: ScriptedNavigationEngine<Request>?
    following = RouteFollowingEngine(
      send: { request, ticket in owner?.record(request, ticket: ticket) },
      // A ticket is the count of requests sent with it, so the request it names is that one.
      abandon: { ticket in owner?.abandon(ticket: ticket) }
    )
    owner = self
  }

  /// sent is every route request the engine sent, in the order they left, each answered when and
  /// how the test says.
  public var sent: [ScriptedRouteRequest<Request>] { requests }

  /// state is the navigation as it stands, `NavigationState.idle` before the first command.
  public var state: NavigationState { following.state }

  /// subscribe returns a stream that yields the state as it is now, then every state that differs
  /// from the one before it, in order, until `close()`.
  public func subscribe() -> AsyncStream<NavigationState> { following.subscribe() }

  /// start asks for a route, a request `sent` holds, and follows it once the test answers it.
  public func start(_ request: Request) { following.start(request) }

  /// reroute asks for a new route where the navigation is `off-route`, and does nothing in any
  /// other status.
  public func reroute(_ request: Request) { following.reroute(request) }

  /// setPosition states where the traveller is and reads it against the route followed, or keeps
  /// it for the route that lands next. It throws a `PositionError` where the position names no
  /// place.
  public func setPosition(_ position: [Double]) throws(PositionError) {
    try following.setPosition(position)
  }

  /// stop ends the navigation, abandoning the request in flight and the one waiting.
  public func stop() { following.stop() }

  /// close abandons the route requests, ends every stream, and makes every later command do
  /// nothing.
  public func close() { following.close() }

  /// record keeps the request the machine sent under `ticket`, answered through it.
  private func record(_ request: Request, ticket: Int) {
    requests.append(
      ScriptedRouteRequest(request: request) { [weak self] answer in
        self?.following.answered(ticket: ticket, with: answer)
      })
  }

  /// abandon marks the request sent under `ticket` abandoned.
  private func abandon(ticket: Int) {
    guard requests.indices.contains(ticket - 1) else { return }
    requests[ticket - 1].abandon()
  }
}
