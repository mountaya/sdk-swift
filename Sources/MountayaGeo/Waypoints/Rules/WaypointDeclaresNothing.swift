import MountayaClient

/// waypointDeclaresNothing is whether a waypoint has no fact for a card to state: no service, no
/// timing, no contact, no photo, no link and no custom field. Its description is no part of it,
/// since a card states the facts under a header that already carries the description.
public func waypointDeclaresNothing(_ waypoint: RestSchema.ItineraryWaypoint) -> Bool {
  waypoint.amenities.isEmpty && waypoint.timing == nil && waypoint.contact == nil
    && ((waypoint.media?.photos ?? nil)?.isEmpty ?? true)
    && ((waypoint.media?.links ?? nil)?.isEmpty ?? true)
    && (waypoint.properties?.isEmpty ?? true)
}
