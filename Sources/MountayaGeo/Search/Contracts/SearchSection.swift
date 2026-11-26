import MountayaClient

/// SearchSection is one section of a search: the branch it answers, how it stands, and its rows,
/// in the order the branch answered them (`geo.search.section-order`).
///
/// It is `Identifiable` by its branch, so a list keyed by it keeps its sections in place as the
/// branches land, and not `Equatable`, since a failed section holds an error.
public struct SearchSection: Sendable, Identifiable {
  /// id is the branch the section answers.
  public var id: DataSchema.SearchTarget
  /// state is how the section stands.
  public var state: SearchSectionState
  /// rows is the section's rows, none while it loads or where it failed.
  public var rows: [SearchRow]

  /// Creates the section of the branch `id`, standing as `state`, holding `rows`.
  public init(id: DataSchema.SearchTarget, state: SearchSectionState, rows: [SearchRow] = []) {
    self.id = id
    self.state = state
    self.rows = rows
  }
}
