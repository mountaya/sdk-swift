import MountayaClient

/// ItinerarySource is how an itinerary is read by its id, and it is the seam that keeps the geo
/// layer from calling the network: the app's own call, `getItinerary` through its client, wired in
/// one line, answering the itinerary with its segments, its groups and its waypoints in one round
/// trip, or throwing what failed, which an element shows as its failure.
///
/// `surface` is the surface the itinerary is read from: nil for the one the credential reads by
/// default, the draft for a member of its organization, and `.published` for the
/// published snapshot. A source is handed to an `ItineraryResourceCache`, one per client, which
/// asks it from the main actor and shares its answer with every engine handed that cache; no read
/// it is asked for is cancelled while the cache stands.
public typealias ItinerarySource =
  @Sendable (_ itineraryId: String, _ surface: RestSchema.ReadSurface?) async throws
  -> RestSchema.ItineraryWithDetails
