import MountayaClient

/// itineraryRow is the row an `itinerary` renders as for `query`: identified `itinerary:` then its
/// id, titled by its name, its second line its distance and ascent for the surface to state in its
/// reader's units, advertising its activity. Picking it opens the itinerary, framed on its extent
/// where the search answered one. An itinerary is addressed by its id, so a missing extent costs
/// the framing and nothing else.
///
/// `nil` where it carries no id.
public func itineraryRow(_ itinerary: DataSchema.ItinerarySearchResult, query: String)
  -> SearchRow?
{
  itineraryRow(itinerary, folded: foldedQuery(query))
}

/// itineraryRow is the row `itinerary` renders as for a query already folded, `foldedQuery(_:)`,
/// as a round builds every row of its answers against one fold of its query.
func itineraryRow(_ itinerary: DataSchema.ItinerarySearchResult, folded query: [Unicode.Scalar])
  -> SearchRow?
{
  guard let id = itinerary.id else { return nil }
  let title = itinerary.name ?? ""
  var activities: [DataSchema.ActivitySlug] = []
  if let activity = itinerary.activitySlug, !activity.rawValue.unicodeScalars.isEmpty {
    activities.append(activity)
  }
  return SearchRow(
    id: "itinerary:\(id)", title: title, matched: highlightRanges(title, folded: query),
    secondary: .metric(distance: itinerary.distance, ascent: itinerary.ascent),
    activities: activities,
    payload: .itinerary(
      itineraryId: id, bounds: boxOrNil(itinerary.bounds), start: placeOrNil(itinerary.start)))
}
