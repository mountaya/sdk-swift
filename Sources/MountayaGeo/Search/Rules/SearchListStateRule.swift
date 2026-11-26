import MountayaClient

/// searchListState answers what a result list shows of `snapshot` under `filter`
/// (`geo.search.list-state`).
///
/// Its rows are those of the sections the filter shows, in the order they render
/// (`sectionsForFilter(_:filter:)`), and each of those sections whose branch failed has a line of
/// its own, beside which a list offers a retry. It says nothing was found only once a round has
/// settled with none in flight, no row under the filter and no failed branch under it: a failure
/// is no empty answer, and a round falling back from the visible area is still in flight. It notes
/// the fall back whenever the round fell back. Its status line announces the failure, else the
/// emptiness, else, once no round is in flight, how many rows it shows, and nothing while a round
/// runs with no failure to announce.
///
/// Its file is `SearchListStateRule.swift`, since Swift refuses a second file of the answer type's
/// name.
public func searchListState(_ snapshot: SearchSnapshot, filter: SearchFilter) -> SearchListState {
  let shown = filter.targets
  let sections = snapshot.sections.filter { section in
    shown.contains { sameText($0, section.id) }
  }
  let rows = sections.flatMap(\.rows)
  let failed = sections.filter { $0.state.failure != nil }
  let isNothingFound = snapshot.isSettled && !snapshot.isSearching && rows.isEmpty && failed.isEmpty
  let status: SearchListStatus?
  if !failed.isEmpty {
    status = .error
  } else if isNothingFound {
    status = .emptyTitle
  } else if !rows.isEmpty, !snapshot.isSearching {
    status = .resultCount(rows.count)
  } else {
    status = nil
  }
  return SearchListState(
    rows: rows, failed: failed, isNothingFound: isNothingFound,
    hasFallbackNote: snapshot.hasFallenBack, status: status)
}
