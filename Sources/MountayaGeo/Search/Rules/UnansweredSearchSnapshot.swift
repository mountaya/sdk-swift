import MountayaClient

/// unansweredSearchSnapshot is what the query `query` in a search box reads as while the search has
/// not answered it (`geo.search.typing-pause`): the skeleton of the round it is owed, every section
/// of `targets` loading and a round in flight, where the search is live, `isLive`, holding a
/// transport, and the query trims to something; and every section settled with nothing otherwise,
/// a blank query, or one with no transport to ask it through, owing no round. Either way no round
/// is settled and no fall back is noted, and it names the query trimmed as a round asks it.
func unansweredSearchSnapshot(_ query: String, isLive: Bool, targets: [DataSchema.SearchTarget])
  -> SearchSnapshot
{
  let asked = trimWhiteSpace(query)
  let asks = isLive && !asked.unicodeScalars.isEmpty
  return SearchSnapshot(
    query: asked, isSearching: asks,
    sections: targets.map { SearchSection(id: $0, state: asks ? .loading : .settled) })
}
