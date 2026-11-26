import Observation

/// NavigationEngine is following a route: the route requests, the status, the progress and the
/// arrival, reported as one `state` a renderer draws. An app codes against it without linking the
/// engine underneath, and every engine answers it alike, since every decision it makes is a rule
/// of the contract's (`sdk/SPEC.md` §14):
///
/// - A route is asked for by `start(_:)`, and at most one request is in flight: one made meanwhile
///   waits, the newest in the place of any already waiting, and the answer to a request something
///   waits behind is dropped for the waiting one, which is sent in its place
///   (`geo.navigation.route-request`).
/// - A position moves the status. Each one `setPosition(_:)` states is read against the route
///   held, whatever the status: the progress first (`geo.navigation.progress`), then whether the
///   traveller is more than 50 m from the route (`geo.navigation.off-route`), then, on the route
///   with progress standing at its end, the arrival. The status moves only as the contract's table
///   moves it (`geo.navigation.status`).
/// - A new route is asked for by `reroute(_:)`, which the table takes only off the route and never
///   while a new route is awaited, so the host decides when to ask and an engine asks at most once
///   per answer: there is no automatic retry.
///
/// An engine is `Observable`, so a SwiftUI view that reads `state` is drawn again when it changes,
/// and a reader outside SwiftUI takes a stream of its own from `subscribe()`. Both are told of a
/// change only where a state differs from the one held, one per command, but for a route that
/// lands while a position is held: the route is reported, then that position's reading on it.
///
/// An engine is bound to the main actor, where SwiftUI reads its state, and each command has its
/// effect before it returns; a host whose positions arrive elsewhere hands each one to the main
/// actor first. After `close()`, every command does nothing and `state` stays as it was.
///
/// `Request` is what the host asks a route for, a destination, waypoints or a segment's id,
/// handed to the engine's route source as it is.
@MainActor
public protocol NavigationEngine<Request>: AnyObject, Observable {
  /// Request is what the host asks a route for.
  associatedtype Request: Sendable

  /// state is the navigation as it stands, `NavigationState.idle` before the first command.
  var state: NavigationState { get }

  /// subscribe returns a stream that yields the state as it is now, then every state that differs
  /// from the one before it, in order, for as long as the stream is held. It ends at `close()`.
  func subscribe() -> AsyncStream<NavigationState>

  /// start asks for a route to follow, and follows it once it lands: the navigation is `routing`
  /// until the answer, and drops the route it held and its reading, since a new start is a new
  /// destination. Where a request is in flight this one waits for its answer, and a later start
  /// takes its place.
  func start(_ request: Request)

  /// reroute asks for a new route from where the traveller is, where the navigation is
  /// `off-route`, and does nothing in any other status: on the route there is nothing to replace,
  /// and while a new route is awaited its answer decides. The route held stays followed until the
  /// new one lands, and stays where the new one fails.
  func reroute(_ request: Request)

  /// setPosition states where the traveller is, `[longitude, latitude]` in degrees with an
  /// optional altitude the engine does not read, and reads it against the route followed. With no
  /// route held it is kept, and read against the route that lands next.
  ///
  /// It throws a `PositionError` where the position names no place, its longitude or its latitude
  /// missing or not finite, and changes nothing then.
  func setPosition(_ position: [Double]) throws(PositionError)

  /// stop ends the navigation: it is `idle` again, holds no route, and abandons the route request
  /// in flight and the one waiting, so the next start is sent at once and a late answer is
  /// dropped.
  func stop()

  /// close abandons the route requests, ends every stream `subscribe()` returned, and makes every
  /// later command do nothing. Calling it again does nothing.
  func close()
}
