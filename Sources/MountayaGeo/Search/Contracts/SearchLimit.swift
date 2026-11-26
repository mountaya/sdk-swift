/// SearchLimit is the cap a search round asks each branch for: a whole number from 1 to
/// `searchLimitMax`, the range the Data API takes (`geo.search.query`).
///
/// Its initializer is the refusal: a cap outside the range is no `SearchLimit`, so a search never
/// asks a round the API would refuse once per branch, as an error line in every section, for a
/// round that did nothing wrong. A search given none asks the API's own default.
public struct SearchLimit: Sendable, Hashable {
  /// value is the cap, from 1 to `searchLimitMax`.
  public let value: Int

  /// Creates the cap `value`, or nil where it lies outside 1 to `searchLimitMax`
  /// (`isSearchLimit(_:)`).
  public init?(_ value: Int) {
    guard isSearchLimit(value) else { return nil }
    self.value = value
  }
}
