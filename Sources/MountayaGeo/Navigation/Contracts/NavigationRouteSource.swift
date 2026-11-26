/// NavigationRouteSource is how a navigation asks for a route, and it is the seam that keeps the
/// geo layer from calling the network: the host's own call, the Data API's `directions` through
/// its client or a saved itinerary's segment, answering the `NavigationRoute` to follow.
///
/// A route is read from the surface that wrote it: its steps through
/// `readDirectionsSteps(_:coordinateCount:)` for the Data API and
/// `readItineraryDirectionsSteps(_:coordinateCount:)` for a REST directions segment. What it throws
/// is the failure the navigation records, in a `NavigationError`'s `cause`. The task asking is
/// cancelled where the navigation abandons the request, by a stop or a close, so a source that
/// honours cancellation ends its own call then, and its answer is dropped whatever it is.
///
/// `Request` is what the host asks a route for, handed to the source as the host made it.
public typealias NavigationRouteSource<Request: Sendable> =
  @Sendable (Request) async throws -> NavigationRoute
