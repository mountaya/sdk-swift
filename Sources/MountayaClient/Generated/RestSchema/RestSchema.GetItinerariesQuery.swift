// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// GetItinerariesQuery is the query of `getItineraries`, one property to a parameter.
  public struct GetItinerariesQuery: Sendable, Hashable, PagedQuery {
    /// The organization to list for. It can only be the key's organization, which
    /// is also what the listing covers when this is omitted; any other identifier
    /// is a `403`, whether or not it exists. A personal resource, owned by no
    /// organization, is never listed under a key.
    public var organization_id: String?
    /// Lists only the itineraries in this publication state: `published` those
    /// with a live publication, `draft` those with none. Omitted, both are
    /// listed. A key alone is served published itineraries only, and so is a
    /// key with a session token minted without `user_id`, so `draft` lists
    /// nothing under either.
    public var status: RestSchema.ItineraryStatus?
    /// `true` lists only private items and `false` only public ones; omitted, both
    /// are listed. It narrows and never widens: what a credential lists is still
    /// decided by the read tiers in this document's introduction, so a key without
    /// a session token naming a member lists no private item whatever this says.
    public var is_private: Bool?
    /// Lists only the itineraries of this activity, one `getActivities` lists.
    public var activity_id: String?
    /// `true` lists only the itineraries filed in at least one collection this
    /// credential lists, and `false` only those filed in none of them. Omitted,
    /// both are listed. A key alone lists the organization's public collections
    /// only, and so does a key with a session token minted without `user_id`,
    /// so under either an itinerary filed only in a private collection counts
    /// as filed in none.
    public var in_collection: Bool?
    /// Lists only what changed at or after this instant, compared with each item's
    /// `updated_at`. With `sort=updated_at`, it is how a client picks up what
    /// changed since its last read without walking the whole listing.
    public var updated_since: Date?
    /// Lists only the items whose `name` contains this text, compared without
    /// regard to case. 1 to 100 characters; leading and trailing whitespace is
    /// ignored.
    public var q: String?
    /// The order the listing is served in, one key: `updated_at` and
    /// `created_at` order by those timestamps and `name` by the itinerary's
    /// name, ascending, and a leading `-` reverses the order. Omitted, the most
    /// recently changed comes first (`-updated_at`). Ties on the key break on
    /// `id`, so the order is total and the same from one page to the next.
    public var sort: RestSchema.GetItinerariesSort?
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

    /// Creates a `GetItinerariesQuery` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.organization_id = nil
      self.status = nil
      self.is_private = nil
      self.activity_id = nil
      self.in_collection = nil
      self.updated_since = nil
      self.q = nil
      self.sort = nil
      self.cursor = nil
      self.limit = nil
      configure(&self)
    }

    /// items is the query, as the request carries it: one item to a value, in the operation's
    /// order, and none for a parameter left `nil`.
    var items: [QueryItem] {
      var items: [QueryItem] = []
      if let value = self.organization_id {
        items.append(.init(name: "organization_id", value: value))
      }
      if let value = self.status {
        items.append(.init(name: "status", value: value.rawValue))
      }
      if let value = self.is_private {
        items.append(.init(name: "is_private", value: String(value)))
      }
      if let value = self.activity_id {
        items.append(.init(name: "activity_id", value: value))
      }
      if let value = self.in_collection {
        items.append(.init(name: "in_collection", value: String(value)))
      }
      if let value = self.updated_since {
        items.append(.init(name: "updated_since", value: Timestamp.string(from: value)))
      }
      if let value = self.q {
        items.append(.init(name: "q", value: value))
      }
      if let value = self.sort {
        items.append(.init(name: "sort", value: value.rawValue))
      }
      if let value = self.cursor {
        items.append(.init(name: "cursor", value: value))
      }
      if let value = self.limit {
        items.append(.init(name: "limit", value: String(value)))
      }
      return items
    }
  }
}
