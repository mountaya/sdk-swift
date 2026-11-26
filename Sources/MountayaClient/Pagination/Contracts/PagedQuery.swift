/// PagedQuery is the query of a listing paged by an opaque cursor: every operation the contract
/// marks with `pagination` takes one, and a `PageWalk` reads the listing through it.
///
/// The walk replaces its `cursor` and `limit` on every request and sends the rest of it as the
/// caller wrote it, filters and `sort` included, since a cursor is bound to the filters and the
/// order it was issued under.
public protocol PagedQuery: Sendable {
  /// cursor is the position a page starts from, or nil for the first page.
  var cursor: String? { get set }
  /// limit is how many rows a page holds at most.
  var limit: Int? { get set }
}
