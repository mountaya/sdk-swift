/// ItineraryResource is what an element handed an itinerary's id shows: nothing while it has no
/// id, nothing while its itinerary is read, every projection at once once it is, and nothing but
/// why where it could not be read (`geo.data.itinerary-resource`).
///
/// No projection is ever shown without the others, and none of an itinerary is shown while
/// another is asked about. A failure holds what the source threw, and a Swift error is no value to
/// compare, so a resource is not `Equatable`: an engine reports a state only where it differs from
/// the one it holds, and two failures are two states.
public enum ItineraryResource: Sendable {
  /// idle is an element with no itinerary to show, which asks nothing.
  case idle
  /// resolving is an element whose itinerary is being read, showing nothing until it lands.
  case resolving
  /// resolved is an element showing its itinerary, every projection at once.
  case resolved(ResolvedItinerary)
  /// failed is an element whose itinerary could not be read, showing nothing, with what its
  /// source threw.
  case failed(any Error)
}
