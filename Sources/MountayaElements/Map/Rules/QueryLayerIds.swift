import MountayaGeo

/// queryLayerIds is the layers a point query asks the renderer about (`map.query.layers`): every
/// layer the map placed in a band the query reads that the live style still holds, in the order the
/// map placed them, or nil where none is left, which asks the renderer nothing.
///
/// A map answers for what it drew, never for its base map, whose roads and landuse are no answer to
/// "what is here", so a query names the layers it placed: `features` every band, `pois` the points
/// of interest band, `zones` the zones band and `itineraries` the itinerary line and point bands, a
/// layer placed at a rank between two bands being in neither. A renderer refuses a layer its style
/// no longer holds, which happens for a beat as a switch of base map replays the map, so such a
/// layer is left out.
func queryLayerIds(_ query: PointQuery, placed: [PlacedLayer], isLive: (String) -> Bool)
  -> [String]?
{
  let bands: [LayerRank]? =
    switch query {
    case .features: nil
    case .pois: [.poi]
    case .zones: [.zone]
    case .itineraries: [.itineraryLine, .itineraryPoint]
    }
  let ids = placed.filter { layer in
    (bands?.contains { $0.rank == layer.rank } ?? true) && isLive(layer.id)
  }.map(\.id)
  return ids.isEmpty ? nil : ids
}
