/// navigationStatusAfter answers the status an event moves a navigation in a status to: the
/// contract's closed table, written out cell by cell rather than derived, so it reads as the
/// contract states it (`geo.navigation.status`).
///
/// A `start` moves every status to `routing` and a `stop` every status to `idle`. A first route
/// that fails is `failed`, since there is nothing to follow, while a new route that fails leaves
/// the traveller `off-route`, still on the route they hold: a reroute fails where the signal does,
/// which is where a traveller most needs the route they already have. While a new route is awaited
/// a position on or off the route moves nothing, so the answer decides, and an answer the
/// navigation is not awaiting moves nothing either.
func navigationStatusAfter(_ status: NavigationStatus, on event: NavigationEvent)
  -> NavigationStatus
{
  switch status {
  case .idle:
    switch event {
    case .start: .routing
    case .routeReceived: .idle
    case .routeFailed: .idle
    case .onRoute: .idle
    case .offRoute: .idle
    case .reroute: .idle
    case .arrived: .idle
    case .stop: .idle
    }
  case .routing:
    switch event {
    case .start: .routing
    case .routeReceived: .navigating
    case .routeFailed: .failed
    case .onRoute: .routing
    case .offRoute: .routing
    case .reroute: .routing
    case .arrived: .routing
    case .stop: .idle
    }
  case .navigating:
    switch event {
    case .start: .routing
    case .routeReceived: .navigating
    case .routeFailed: .navigating
    case .onRoute: .navigating
    case .offRoute: .offRoute
    case .reroute: .navigating
    case .arrived: .arrived
    case .stop: .idle
    }
  case .offRoute:
    switch event {
    case .start: .routing
    case .routeReceived: .offRoute
    case .routeFailed: .offRoute
    case .onRoute: .navigating
    case .offRoute: .offRoute
    case .reroute: .rerouting
    case .arrived: .arrived
    case .stop: .idle
    }
  case .rerouting:
    switch event {
    case .start: .routing
    case .routeReceived: .navigating
    case .routeFailed: .offRoute
    case .onRoute: .rerouting
    case .offRoute: .rerouting
    case .reroute: .rerouting
    case .arrived: .arrived
    case .stop: .idle
    }
  case .arrived:
    switch event {
    case .start: .routing
    case .routeReceived: .arrived
    case .routeFailed: .arrived
    case .onRoute: .arrived
    case .offRoute: .arrived
    case .reroute: .arrived
    case .arrived: .arrived
    case .stop: .idle
    }
  case .failed:
    switch event {
    case .start: .routing
    case .routeReceived: .failed
    case .routeFailed: .failed
    case .onRoute: .failed
    case .offRoute: .failed
    case .reroute: .failed
    case .arrived: .failed
    case .stop: .idle
    }
  }
}
