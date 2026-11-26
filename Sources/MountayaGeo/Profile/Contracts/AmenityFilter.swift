import MountayaClient

/// AmenityFilter is what a waypoint table filtered by its places' services shows
/// (`geo.profile.amenity-filter`): the services a reader can pick, one chip each, in the order the
/// reader's names for them sort, and the rows a choice of them leaves.
public struct AmenityFilter: Sendable, Hashable {
  /// available is each service the places offer, once, sorted by the reader's name for it.
  public var available: [RestSchema.WaypointAmenity]
  /// shown is the rows whose place offers every service picked, in their order.
  public var shown: [ItineraryWaypointRow]

  /// Creates a filter from the services offered and the rows shown.
  public init(available: [RestSchema.WaypointAmenity], shown: [ItineraryWaypointRow]) {
    self.available = available
    self.shown = shown
  }

  /// Two filters are equal where they offer the same services, written alike, over the same rows.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameText(lhs.available, rhs.available) && lhs.shown == rhs.shown
  }

  /// hash feeds the services, then the rows.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(available)
    hasher.combine(shown)
  }
}
