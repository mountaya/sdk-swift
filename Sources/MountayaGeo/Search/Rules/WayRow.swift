import MountayaClient

/// wayRow is the row a named `way` renders as for `query`: identified `way:` then its OpenStreetMap
/// type and id, titled by its name else its `highway` tag, its second line its tag, its grade or
/// surface, its city or region and country, and advertising the activities it suits. Picking it
/// moves the camera to its anchor, frames its bounds and traces its line where the search verified
/// one.
///
/// `nil` where its point names no place, or where it carries no OpenStreetMap type and id.
public func wayRow(
  _ way: DataSchema.Way, query: String, wording: SearchWording = SearchWording()
) -> SearchRow? {
  wayRow(way, folded: foldedQuery(query), wording: wording)
}

/// wayRow is the row `way` renders as for a query already folded, `foldedQuery(_:)`, as a round
/// builds every row of its answers against one fold of its query.
func wayRow(
  _ way: DataSchema.Way, folded query: [Unicode.Scalar], wording: SearchWording
) -> SearchRow? {
  guard let anchor = placeOrNil(way.point), let type = way.osm?.type, let id = way.osm?.id else {
    return nil
  }
  let title = wayTitle(way, wording: wording)
  return SearchRow(
    id: "way:\(type.rawValue):\(id)", title: title, matched: highlightRanges(title, folded: query),
    secondary: textSecondary(describeWay(way, wording: wording)),
    activities: way.activityCompatible ?? [],
    payload: .way(anchor: anchor, bounds: boxOrNil(way.bounds), coordinates: way.coordinates))
}
