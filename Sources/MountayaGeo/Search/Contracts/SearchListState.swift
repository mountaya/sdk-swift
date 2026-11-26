/// SearchListState is what a result list shows of a search under a filter, before any of it is
/// worded or drawn (`geo.search.list-state`): its rows, its failed branches, whether it says nothing
/// was found, whether it notes the round fell back from the visible area, and what its status line
/// announces.
///
/// It is not `Equatable`, since a failed section holds an error.
public struct SearchListState: Sendable {
  /// rows is the rows of the sections the filter shows, in the order they render.
  public var rows: [SearchRow]
  /// failed is the sections under the filter whose branch failed, in the order they render, each
  /// a line of its own beside a retry.
  public var failed: [SearchSection]
  /// isNothingFound is whether the list says nothing was found.
  public var isNothingFound: Bool
  /// hasFallbackNote is whether the list notes that the round fell back from the visible area to
  /// everywhere.
  public var hasFallbackNote: Bool
  /// status is what the status line announces, or nil where it announces nothing.
  public var status: SearchListStatus?

  /// Creates what a list shows from its rows, its failed sections, its two flags and its status.
  public init(
    rows: [SearchRow], failed: [SearchSection], isNothingFound: Bool, hasFallbackNote: Bool,
    status: SearchListStatus?
  ) {
    self.rows = rows
    self.failed = failed
    self.isNothingFound = isNothingFound
    self.hasFallbackNote = hasFallbackNote
    self.status = status
  }
}
