/// PointQuery is a map's point query, named by what it answers (`map.query.layers`).
enum PointQuery: Sendable, CaseIterable {
  /// features answers every feature the map drew, in every band.
  case features
  /// pois answers the points of interest, the POI band.
  case pois
  /// zones answers the zones, the zone band.
  case zones
  /// itineraries answers an itinerary's routed lines and waypoints, the itinerary line and point
  /// bands.
  case itineraries
}
