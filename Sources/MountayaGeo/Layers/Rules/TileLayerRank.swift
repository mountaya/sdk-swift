import MountayaClient

/// poiSourceLayers are the source layers of the base map's vector tiles that carry points of
/// interest, `road` among them for its parking aisles. A query of the features under a pointer
/// names the same set the ranks name, so it is published rather than restated.
public let poiSourceLayers = [
  "parking", "poi_accommodation", "poi_food", "poi_healthcare", "poi_tourism", "road",
  "street_furniture",
]

/// tileSourceLayerRanks is the band each source layer Mountaya draws from takes: an itinerary's
/// lines, restricted stretches and points, a zone's fills and the points of interest.
///
/// It is a dictionary a consumer patches rather than a table fixed here: an app whose own overlay
/// draws above the points of interest and beneath an itinerary's waypoints hands
/// `tileLayerRank(_:ranks:)` the table with `"my_overlay"` set to `LayerRank.poi.rank + 2`.
public let tileSourceLayerRanks: [String: Int] = {
  var ranks = [
    "itinerary_lines": LayerRank.itineraryLine.rank,
    "itinerary_restrictions": LayerRank.itineraryRestriction.rank,
    "itinerary_points": LayerRank.itineraryPoint.rank,
    "fills": LayerRank.zone.rank,
  ]
  for layer in poiSourceLayers {
    ranks[layer] = LayerRank.poi.rank
  }
  return ranks
}()

/// tileLayerRank is the rank `layer` of a tile specification draws at: a hillshade at
/// `LayerRank.hillshade` whatever source layer its tiles ride in, since it shades the terrain, and
/// any other the rank `ranks` gives its `source_layer`, `LayerRank.overlay` for one the table does
/// not know. The source layer is matched exactly, letter case included.
public func tileLayerRank(
  _ layer: TileSchema.TileLayer, ranks: [String: Int] = tileSourceLayerRanks
) -> Int {
  if layer.type == .hillshade {
    return LayerRank.hillshade.rank
  }
  // A dictionary finds a key by canonical equivalence; the source layer is matched by its scalars.
  guard let index = ranks.index(forKey: layer.source_layer),
    sameText(ranks[index].key, layer.source_layer)
  else { return LayerRank.overlay.rank }
  return ranks[index].value
}
