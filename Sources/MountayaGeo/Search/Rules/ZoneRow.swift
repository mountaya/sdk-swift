import MountayaClient

/// zoneRow is the row a `zone` renders as for `query`: identified `zone:` then its id, titled by its
/// name, its second line its own description where it has one. Picking it opens the zone, at its
/// anchor and framed on its extent where the search answered them.
///
/// `nil` where it carries no id.
public func zoneRow(_ zone: DataSchema.ZoneSearchResult, query: String) -> SearchRow? {
  zoneRow(zone, folded: foldedQuery(query))
}

/// zoneRow is the row `zone` renders as for a query already folded, `foldedQuery(_:)`, as a round
/// builds every row of its answers against one fold of its query.
func zoneRow(_ zone: DataSchema.ZoneSearchResult, folded query: [Unicode.Scalar]) -> SearchRow? {
  guard let id = zone.id else { return nil }
  let title = zone.name ?? ""
  return SearchRow(
    id: "zone:\(id)", title: title, matched: highlightRanges(title, folded: query),
    secondary: textSecondary(zone.description), activities: [],
    payload: .zone(zoneId: id, point: placeOrNil(zone.point), bounds: boxOrNil(zone.bounds)))
}
