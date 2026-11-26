import MountayaGeo

/// MapLayerRegistry is the one registry every layer a map draws above its base map goes through,
/// which is what makes a layer's place the contract's rank and never the order code happened to
/// add it in (`geo.layers.order`).
///
/// It holds the layers bottom to top: a layer of a greater rank above one of a lesser, two of one
/// rank in the order they were placed, the later above (`map.layers.rank-insertion`). A layer
/// placed again under an id in use at the rank it holds keeps its place and takes the new
/// definition there, and one placed again at another rank moves to the top of its new band. An id
/// is matched by its scalars.
///
/// It also holds the order the layers were placed in, which a point query asks the renderer about
/// them in (`map.query.layers`): a layer placed again at the rank it holds keeps its place there,
/// and one placed at another rank is placed anew, last.
struct MapLayerRegistry: Sendable, Equatable {
  /// layers is every layer held, bottom to top.
  private(set) var layers: [MapLayer] = []
  /// placed is the id of every layer held, in the order the layers were placed.
  private var placed: [String] = []

  /// placement is every layer held, its id and its rank, in the order the layers were placed.
  var placement: [PlacedLayer] {
    placed.compactMap { id in layer(id).map { PlacedLayer(id: id, rank: $0.rank) } }
  }

  /// add places `layer` above every layer of its rank or a lesser one and below every layer of a
  /// greater rank, or, where a layer of its id is held at its rank, in that layer's place.
  mutating func add(_ layer: MapLayer) {
    if let held = layers.firstIndex(where: { sameText($0.id, layer.id) }),
      layers[held].rank == layer.rank
    {
      layers[held] = layer
      return
    }
    placed.removeAll { sameText($0, layer.id) }
    placed.append(layer.id)
    layers.removeAll { sameText($0.id, layer.id) }
    let place = layers.firstIndex { $0.rank > layer.rank } ?? layers.endIndex
    layers.insert(layer, at: place)
  }

  /// layer returns the layer held under `id`, or nil where none is.
  func layer(_ id: String) -> MapLayer? {
    layers.first { sameText($0.id, id) }
  }

  /// replace changes the layer held under `id` in its place, keeping its rank, and tells whether
  /// one was held.
  mutating func replace(_ id: String, with layer: MapLayer) -> Bool {
    guard let place = layers.firstIndex(where: { sameText($0.id, id) }) else { return false }
    layers[place] = layer
    return true
  }

  /// remove takes the layer held under `id` off, and tells whether one was held.
  @discardableResult
  mutating func remove(_ id: String) -> Bool {
    let count = layers.count
    layers.removeAll { sameText($0.id, id) }
    placed.removeAll { sameText($0, id) }
    return layers.count != count
  }

  /// removeLayers takes off every layer drawing from the source of id `source`.
  mutating func removeLayers(drawingFrom source: String) {
    let drawing = layers.filter { sameText($0.source, source) }.map(\.id)
    layers.removeAll { sameText($0.source, source) }
    placed.removeAll { id in drawing.contains { sameText($0, id) } }
  }
}
