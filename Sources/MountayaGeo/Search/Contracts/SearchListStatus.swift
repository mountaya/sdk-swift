/// SearchListStatus is what a result list's status line announces (`geo.search.list-state`), each
/// case named by the key of the word it reads in the `search` section of the elements' words: that
/// a branch failed, that nothing was found, or how many rows the list shows.
public enum SearchListStatus: Sendable, Hashable {
  /// error announces that a branch under the filter failed, `search.error`.
  case error
  /// emptyTitle announces that nothing was found, `search.emptyTitle`.
  case emptyTitle
  /// resultCount announces how many rows the list shows, `search.resultCount`, a counted word
  /// (`geo.i18n.counted-words`).
  case resultCount(Int)

  /// key is the key of the word the status reads in the `search` section: `error`, `emptyTitle` or
  /// `resultCount`.
  public var key: String {
    switch self {
    case .error: "error"
    case .emptyTitle: "emptyTitle"
    case .resultCount: "resultCount"
    }
  }
}
