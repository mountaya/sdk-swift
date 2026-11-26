/// NavigationEvent is everything a navigation is told, one of a closed set, in the order the
/// contract lists them: a route asked for, the answer to the request it acts on, a position read
/// against the route followed, a new route asked for from the traveller's position, the arrival,
/// and the end (`geo.navigation.status`).
///
/// Internal, as the table it moves a status by is: a consumer observes the status an engine
/// reports, and tells the engine what to do through its commands, never by naming an event.
enum NavigationEvent: String, CaseIterable, Sendable {
  /// start is a route asked for, to a new destination.
  case start
  /// routeReceived is a route the request the navigation acts on answered.
  case routeReceived = "route-received"
  /// routeFailed is the request the navigation acts on failing.
  case routeFailed = "route-failed"
  /// onRoute is a position read within the off-route threshold of the route followed.
  case onRoute = "on-route"
  /// offRoute is a position read past the off-route threshold of the route followed.
  case offRoute = "off-route"
  /// reroute is a new route asked for, from where the traveller is.
  case reroute
  /// arrived is the traveller arriving.
  case arrived
  /// stop is the navigation ending.
  case stop

  /// id is the event as the contract spells it.
  var id: String { rawValue }
}
