/// pointZoom is the zoom a camera flies to on a picked result that states a point and no extent,
/// close enough to read the place it lands on (`geo.search.pick`).
public let pointZoom: Double = 13

/// pickTarget answers what picking a search result does to a map (`geo.search.pick`): it frames
/// the result's extent where it states one and otherwise flies to its point at `pointZoom`, then
/// marks it with the map's search highlight (`map.search.result-highlight`).
///
/// A place, a point of interest and a way are marked as themselves, a way with its extent and its
/// line where it states them; an itinerary is marked at its start and a zone at its point, each as a
/// place is. A result with neither an extent nor a point, which a collection always is, a set of
/// itineraries with no place of its own, moves nothing and marks nothing. An extent is framed as
/// the result writes it, across the antimeridian where its west edge lies east of its east one.
///
/// The mark is what the map's search highlight is handed, so a surface that marks every pick hands
/// it even where it is nil, which takes the mark of the pick before down.
public func pickTarget(_ payload: SearchRowPayload) -> SearchPick {
  func pick(bounds: [Double]?, point: [Double]?, mark: SearchHighlight?) -> SearchPick {
    if let bounds {
      return SearchPick(camera: .fit(bounds: bounds), mark: mark)
    }
    if let point {
      return SearchPick(camera: .fly(center: point, zoom: pointZoom), mark: mark)
    }
    return SearchPick(camera: nil, mark: mark)
  }
  func place(_ point: [Double]?) -> SearchHighlight? {
    point.map { .place(point: $0) }
  }
  switch payload {
  case .place(let point, let bounds):
    return pick(bounds: bounds, point: point, mark: place(point))
  case .poi(let point, let category):
    return pick(bounds: nil, point: point, mark: .poi(point: point, category: category))
  case .way(let anchor, let bounds, let coordinates):
    return pick(
      bounds: bounds, point: anchor,
      mark: .way(anchor: anchor, bounds: bounds, coordinates: coordinates))
  case .itinerary(_, let bounds, let start):
    return pick(bounds: bounds, point: start, mark: place(start))
  case .zone(_, let point, let bounds):
    return pick(bounds: bounds, point: point, mark: place(point))
  case .collection:
    return pick(bounds: nil, point: nil, mark: nil)
  }
}
