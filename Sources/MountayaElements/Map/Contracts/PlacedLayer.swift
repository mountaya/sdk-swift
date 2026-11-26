/// PlacedLayer is a layer a map placed in its rank bands, as a point query reads it: its id and the
/// rank it was placed at (`map.query.layers`).
struct PlacedLayer: Sendable, Equatable {
  /// id is the layer's id.
  let id: String
  /// rank is the rank the layer was placed at.
  let rank: Int
}
