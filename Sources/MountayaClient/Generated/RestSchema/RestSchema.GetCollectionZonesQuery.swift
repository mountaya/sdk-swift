// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// GetCollectionZonesQuery is the query of `getCollectionZones`, one property to a parameter.
  public struct GetCollectionZonesQuery: Sendable, Hashable, PagedQuery {
    /// Where the page starts: the `next_cursor` the previous page reported at
    /// `extensions.metadata.pagination`, sent back unchanged. Omitted, the listing
    /// starts at its first item.
    ///
    /// A cursor is opaque: it is not an offset and not an identifier, and a client
    /// never builds or edits one, and it is never longer than 1024 characters. It
    /// is bound to the operation that issued it, to its filters and its `sort`,
    /// and to the scope it listed, such as the organization or the collection in
    /// the path or the key's own organization. On `getItineraries`, `getZones`
    /// and `getCollections`, whose scope `organization_id` may leave implicit, it
    /// is bound as well to the tier of the credential it was issued to, a key
    /// alone (or with a session token minted without `user_id`, which reads as
    /// one) or a key with a session token naming a member. The next page is asked
    /// for the same way. A cursor sent to another operation, with different
    /// filters, a different `sort`, another scope or, on those three, another tier
    /// of credential, or altered in any way, is a `400` at
    /// `["request", "query", "cursor"]`. On every listing, each page applies the
    /// read tier of the credential that asks for it. Paging is by position in the
    /// sort order rather than by count, so an item whose sort key does not change
    /// is never skipped or served twice, whatever is created or deleted between
    /// two pages.
    public var cursor: String?
    /// How many items one page holds, between 1 and 100; 50 when omitted, on every
    /// listing that pages. `extensions.metadata.pagination.limit` reports the size
    /// the page was served at. A page shorter than `limit` is not how the end is
    /// told: the end is a `next_cursor` of `null`. The page is cut after
    /// authorization, so it never widens what a caller can read.
    public var limit: Int?
    /// The order the listing is served in, by one key: `updated_at` or `name`,
    /// ascending as written and descending with a leading `-`. `-updated_at`
    /// when omitted, so the zone changed last comes first. Ties break on `id`,
    /// so no two items share a place in the order, and a page boundary never
    /// falls between two that compare equal.
    public var sort: RestSchema.GetCollectionZonesSort?

    /// Creates a `GetCollectionZonesQuery` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.cursor = nil
      self.limit = nil
      self.sort = nil
      configure(&self)
    }

    /// items is the query, as the request carries it: one item to a value, in the operation's
    /// order, and none for a parameter left `nil`.
    var items: [QueryItem] {
      var items: [QueryItem] = []
      if let value = self.cursor {
        items.append(.init(name: "cursor", value: value))
      }
      if let value = self.limit {
        items.append(.init(name: "limit", value: String(value)))
      }
      if let value = self.sort {
        items.append(.init(name: "sort", value: value.rawValue))
      }
      return items
    }
  }
}
