/// AnalysisKind is a kind of Data API result a map draws, each from a source of its own through
/// the layers its kind names, at its kind's rank (`map.analysis.layers`).
enum AnalysisKind: String, CaseIterable, Sendable {
  /// directions is a routed itinerary between waypoints.
  case directions
  /// suggestions is a set of suggested itineraries, the chosen one solid and the rest dashed.
  case suggestions
  /// isochrones is the areas reached within each range of an origin.
  case isochrones
  /// places is the answer of a place search, `geocode`.
  case places
  /// matrix is the costs between locations, drawn as connectors between them.
  case matrix
  /// pois is the answer of a points of interest query, one at a time.
  case pois
}
