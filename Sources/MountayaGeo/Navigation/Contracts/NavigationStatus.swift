/// NavigationStatus is the status a navigation is in, one of a closed set, so a renderer draws
/// every status there is and a test names every transition (`geo.navigation.status`).
///
/// The cases are declared in the order the contract lists them, from `idle`: asking for a first
/// route, following one, off it, asking for a new one from there, at its end, and with no route to
/// follow after a first request failed. That is the order `allCases` yields, not the order of
/// their ids. What moves a navigation from one to another is the contract's closed table, which
/// every engine holds.
public enum NavigationStatus: String, CaseIterable, Sendable {
  /// idle is following nothing and asking for nothing: where a navigation starts, and where a stop
  /// leaves it.
  case idle
  /// routing is asking for a first route, with none to follow yet.
  case routing
  /// navigating is following a route, on it.
  case navigating
  /// offRoute is following a route, more than the off-route threshold from it.
  case offRoute = "off-route"
  /// rerouting is off the route, asking for a new one from there, and still following the one
  /// held.
  case rerouting
  /// arrived is on the route, with no distance left to its end.
  case arrived
  /// failed is a first route asked for that failed, so there is no route to follow.
  case failed

  /// id is the status as the contract spells it.
  public var id: String { rawValue }
}
