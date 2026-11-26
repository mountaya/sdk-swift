import MountayaClient

/// poiRow is the row a point of interest `poi` renders as for `query`: identified `poi:` then its
/// OpenStreetMap type and id, titled by its name else its category, its second line its category,
/// then its elevation where it is meaningful and otherwise its distance from the search's origin,
/// then its city or region and country. Its category rides to the payload, where it picks the pin.
///
/// `nil` where its point names no place, or where it carries no OpenStreetMap type and id.
public func poiRow(
  _ poi: DataSchema.POI, query: String, wording: SearchWording = SearchWording()
) -> SearchRow? {
  poiRow(poi, folded: foldedQuery(query), wording: wording)
}

/// poiRow is the row `poi` renders as for a query already folded, `foldedQuery(_:)`, as a round
/// builds every row of its answers against one fold of its query.
func poiRow(
  _ poi: DataSchema.POI, folded query: [Unicode.Scalar], wording: SearchWording
) -> SearchRow? {
  guard let point = placeOrNil(poi.point), let type = poi.osm?.type, let id = poi.osm?.id else {
    return nil
  }
  let title = poiTitle(poi, wording: wording)
  return SearchRow(
    id: "poi:\(type.rawValue):\(id)", title: title, matched: highlightRanges(title, folded: query),
    secondary: textSecondary(describePoi(poi, wording: wording)), activities: [],
    payload: .poi(point: point, category: poi.category))
}
