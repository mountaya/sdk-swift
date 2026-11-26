/// SearchSnapshot is a search as a list shows it at one moment: the query its rows answer, whether
/// a round is in flight, whether a round has settled, whether the round fell back from the visible
/// area to everywhere, and its sections, in the order they render.
///
/// `query` is the query trimmed as a round asks it. `isSettled` is whether a round has settled
/// with none in flight: a round confined to the visible area that found nothing asks once more
/// everywhere, and between its two passes every section stands settled and empty, which is no
/// answer yet, so a list says nothing was found only once `isSettled` holds
/// (`geo.search.broaden`, `geo.search.list-state`).
///
/// It is not `Equatable`, since a failed section holds an error.
public struct SearchSnapshot: Sendable {
  /// query is the query the rows answer, trimmed of the white space at its ends.
  public var query: String
  /// isSearching is whether a round is in flight.
  public var isSearching: Bool
  /// isSettled is whether a round has settled and none is in flight.
  public var isSettled: Bool
  /// hasFallenBack is whether the round fell back from the visible area to everywhere, having
  /// found nothing within it.
  public var hasFallenBack: Bool
  /// sections is the search's sections, one per branch, in the order they render.
  public var sections: [SearchSection]

  /// Creates a snapshot of the query `query` its rows answer, the flags it stands by, and its
  /// sections.
  public init(
    query: String, isSearching: Bool = false, isSettled: Bool = false,
    hasFallenBack: Bool = false, sections: [SearchSection] = []
  ) {
    self.query = query
    self.isSearching = isSearching
    self.isSettled = isSettled
    self.hasFallenBack = hasFallenBack
    self.sections = sections
  }
}
