import Foundation

/// DeclaredQuery is the query of a listing walked by its declaration, `Mountaya.walk`: the caller's
/// names and values, in their order, and in place of any `cursor` and `limit` among them, the
/// walk's.
///
/// The first `cursor` the caller names is the one the walk resumes from, and the first `limit` the
/// one it holds before the walk sets its page size, as `sdk-kotlin`'s walk by declaration reads
/// them.
struct DeclaredQuery: PagedQuery {
  /// Item is one name and value of the caller's.
  private struct Item: Sendable {
    let name: String
    let value: String?
  }

  /// rest is the caller's names and values but its cursor and its limit, in their order.
  private let rest: [Item]
  /// cursor is the position a page starts from, or nil for the first page.
  var cursor: String?
  /// limit is how many rows a page holds at most.
  var limit: Int?

  /// Creates the query of `items`, the caller's.
  init(_ items: [URLQueryItem]) {
    rest = items.filter { $0.name != "cursor" && $0.name != "limit" }
      .map { Item(name: $0.name, value: $0.value) }
    cursor = items.first { $0.name == "cursor" }?.value
    limit = items.first { $0.name == "limit" }?.value.flatMap { Int($0) }
  }

  /// items is what a page sends: the caller's names and values, then the cursor where there is
  /// one, then the limit.
  var items: [URLQueryItem] {
    rest.map { URLQueryItem(name: $0.name, value: $0.value) }
      + [
        cursor.map { URLQueryItem(name: "cursor", value: $0) },
        limit.map { URLQueryItem(name: "limit", value: String($0)) },
      ].compactMap { $0 }
  }
}

/// DeclaredPage is the metadata of a page of a listing walked by its declaration: where the page
/// after it starts, the `pagination.next_cursor` the envelope's metadata states as text, and none
/// where it states no text there, which ends the walk.
struct DeclaredPage: PageMetadata {
  /// nextCursor is the cursor of the page after this one, or nil on the last page.
  let nextCursor: String?

  /// Creates the metadata a page's `extensions.metadata` states, nil where it states none.
  init(_ metadata: JSONValue?) {
    guard case .object(let members)? = metadata,
      case .object(let pagination)? = members["pagination"],
      case .string(let next)? = pagination["next_cursor"]
    else {
      nextCursor = nil
      return
    }
    nextCursor = next
  }
}
