import MountayaClient

/// searchSectionOf is the section the branch `branch` of a round fills with `result`, the Data
/// API's answer to its request, its rows built for `query`, the query the round asked, folded once
/// for the round by `foldedQuery(_:)`, and worded by `wording` (`geo.search.live-round`,
/// `geo.search.rows`).
///
/// An error the answer reports for the branch wins over whatever came with it: the section reads
/// it as a `SearchBranchError`, and the branches beside it are left as they are. Otherwise the
/// section is settled with a row for each result of the branch's own member of the answer that
/// renders as one, in the order the answer lists them, and none where the member is absent. Every
/// row is matched against the one fold, so a section of many rows folds its query no more than a
/// section of one.
func searchSectionOf(
  _ result: DataSchema.SearchResult, branch: DataSchema.SearchTarget,
  folded query: [Unicode.Scalar], wording: SearchWording
) -> SearchSection {
  if let reported = result.errors?.first(where: { sameText($0.target, branch) }) {
    return SearchSection(
      id: branch,
      state: .failed(
        SearchBranchError(target: branch, code: reported.code, message: reported.message)))
  }
  let rows: [SearchRow]
  if sameText(branch, .places) {
    rows = (result.places?.places ?? []).compactMap {
      placeRow($0, folded: query, wording: wording)
    }
  } else if sameText(branch, .pois) {
    rows = (result.pois?.pois ?? []).compactMap { poiRow($0, folded: query, wording: wording) }
  } else if sameText(branch, .ways) {
    rows = (result.ways?.ways ?? []).compactMap { wayRow($0, folded: query, wording: wording) }
  } else if sameText(branch, .itineraries) {
    rows = (result.itineraries?.itineraries ?? []).compactMap { itineraryRow($0, folded: query) }
  } else if sameText(branch, .collections) {
    rows = (result.collections?.collections ?? []).compactMap {
      collectionRow($0, folded: query)
    }
  } else if sameText(branch, .zones) {
    rows = (result.zones?.zones ?? []).compactMap { zoneRow($0, folded: query) }
  } else {
    rows = []
  }
  return SearchSection(id: branch, state: .settled, rows: rows)
}
