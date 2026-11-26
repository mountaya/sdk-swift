import MountayaClient

/// itineraryBounds is the box a drawn itinerary is framed on (`geo.camera.content-bounds`): the
/// box `boundsOf(_:)` draws around every position of every segment's stored geometry, a directions
/// segment's vias included, so a chain straddling the antimeridian is framed across it with its
/// east edge past 180. The itinerary's places, its waypoints, are no segment's and are left out.
///
/// A segment with no geometry yet adds nothing, whatever its place in the chain, and the answer is
/// nil where no segment's geometry names a place: such an itinerary frames nothing.
public func itineraryBounds(_ segments: [RestSchema.ItinerarySegment]) -> [Double]? {
  boundsOf(segments.compactMap(\.geojson))
}
