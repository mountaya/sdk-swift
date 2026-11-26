import MountayaClient

/// itineraryGeometry is the one geometry an itinerary's profile walks: a GeometryCollection of its
/// segments' geometries in chain order, by their `position`, two at one position in the order they
/// are listed, each as its segment stores it, a segment with none left out.
///
/// The profile lays every line a geometry holds end to end on one distance axis
/// (`buildElevationSeries(_:maxPoints:)`), so an itinerary stored as many legs profiles as one
/// curve, each leg's stretch the length of its own lines. It is nil where no segment carries a
/// geometry, so a reader draws the empty state a missing itinerary draws, rather than a collection
/// that reads as an itinerary of no length.
public func itineraryGeometry(_ segments: [RestSchema.ItinerarySegment]) -> GeoJSONGeometry? {
  let geometries = inChainOrder(segments, position: \.position).compactMap(\.geojson)
  guard !geometries.isEmpty else { return nil }
  return .geometryCollection(GeoJSONGeometryCollection(geometries: geometries))
}
