import MountayaClient

/// placeRow is the row a geocoded `place` renders as for `query`, the query the round asked:
/// identified `place:` then its OpenStreetMap type and id, titled by its name (else its address
/// label, else its category), emphasizing what `query` matched, worded by `wording`, its second
/// line its category, region and country. Picking it moves the camera to its point, its longitude
/// and latitude, and frames its bounds where they are four finite numbers.
///
/// `nil`, no row, where its point names no place, since picking it would go nowhere, and where it
/// carries no OpenStreetMap type and id, since a row with no identity cannot be keyed.
public func placeRow(
  _ place: DataSchema.Place, query: String, wording: SearchWording = SearchWording()
) -> SearchRow? {
  placeRow(place, folded: foldedQuery(query), wording: wording)
}

/// placeRow is the row `place` renders as for a query already folded, `foldedQuery(_:)`, as a
/// round builds every row of its answers against one fold of its query.
func placeRow(
  _ place: DataSchema.Place, folded query: [Unicode.Scalar], wording: SearchWording
) -> SearchRow? {
  guard let point = placeOrNil(place.point), let type = place.osm?.type, let id = place.osm?.id
  else { return nil }
  let title = placeTitle(place, wording: wording)
  return SearchRow(
    id: "place:\(type.rawValue):\(id)", title: title,
    matched: highlightRanges(title, folded: query),
    secondary: textSecondary(describePlace(place, wording: wording)), activities: [],
    payload: .place(point: point, bounds: boxOrNil(place.bounds)))
}
