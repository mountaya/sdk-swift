// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// A collection grouping itineraries and zones for shared access and map
  /// rendering, as it appears to the calling credential: the collection itself,
  /// what it contains, the `role` the request carries in the organization that owns
  /// it, and the tile sources that render its contents on a map.
  ///
  /// `role` is an ORGANIZATION role, not a per-collection grant. A read made with a
  /// publishable key or a share token reports the read-only floor `viewer`, because
  /// neither holds a membership; the response to a write reports the role of the
  /// user the session token names.
  public struct Collection: Sendable, Hashable, Codable {
    /// How many itineraries and zones the collection holds, whoever asks: a
    /// member the caller cannot see is counted all the same, so walking a
    /// member listing to its end can yield fewer than this.
    public var count: RestSchema.CollectionCount
    /// Timestamp of the collection's creation.
    public var created_at: Date
    /// The user who created the collection. It is the author rather than the last
    /// editor, and it does not move when another member edits the collection.
    public var created_by: RestSchema.RelationToUser
    /// Free-text description of the collection. Null when it has none.
    public var description: String?
    /// The version of everything a read of this collection returns, the one
    /// the `ETag` of that read carries, opaque and compared whole. It moves on
    /// every write that changes the read, its contents included: an itinerary
    /// or a zone added, removed or moved. Send it as `If-Match` to make a write
    /// to the collection conditional.
    public var etag: String
    /// Unique identifier of the collection.
    public var id: String
    /// Whether the collection is private. A private collection is reached only
    /// with the key of the organization that owns it, so a private personal
    /// collection, owned by no organization, is reached by no key. A public
    /// collection is readable by id, read-only, with any publishable key that
    /// knows its identifier, and it is listed only in its own organization's
    /// listings. A share token reaches only what its link names, and reaches the
    /// collection it names whatever this says. Public never grants editing,
    /// which takes a write role in the owning organization.
    public var is_private: Bool
    /// Display name of the collection.
    public var name: String
    /// Identifier of the organization that owns this collection. Null for a personal
    /// collection, made from an individual account and owned by no organization.
    public var organization_id: String?
    /// The role this request carries in the organization that owns the
    /// collection, not a property of the collection: `viewer` on a read made with
    /// a publishable key or a share token, neither of which holds a membership,
    /// and on a write's response the role of the user the session token names.
    /// Offer edit controls from the role of the member who will act.
    public var role: RestSchema.OrganizationRole
    /// Tile sources available for rendering this collection on a map.
    public var sources: [RestSchema.TileSource]
    /// When the collection itself last changed. Every `patchCollection` moves
    /// it, even one that changes nothing, while adding, removing or reordering
    /// its itineraries and zones never does. Always present: it equals
    /// `created_at` until the first patch.
    public var updated_at: Date

    /// Creates a `Collection` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      count: RestSchema.CollectionCount,
      created_at: Date,
      created_by: RestSchema.RelationToUser,
      description: String?,
      etag: String,
      id: String,
      is_private: Bool,
      name: String,
      organization_id: String?,
      role: RestSchema.OrganizationRole,
      sources: [RestSchema.TileSource],
      updated_at: Date,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.count = count
      self.created_at = created_at
      self.created_by = created_by
      self.description = description
      self.etag = etag
      self.id = id
      self.is_private = is_private
      self.name = name
      self.organization_id = organization_id
      self.role = role
      self.sources = sources
      self.updated_at = updated_at
      configure(&self)
    }

    /// Reads a `Collection` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.count = try container.decode(RestSchema.CollectionCount.self, forKey: "count")
      self.created_at = try container.decodeWired(Date.self, forKey: "created_at")
      self.created_by = try container.decode(RestSchema.RelationToUser.self, forKey: "created_by")
      self.description = try container.decodeIfPresent(String.self, forKey: "description")
      self.etag = try container.decode(String.self, forKey: "etag")
      self.id = try container.decode(String.self, forKey: "id")
      self.is_private = try container.decode(Bool.self, forKey: "is_private")
      self.name = try container.decode(String.self, forKey: "name")
      self.organization_id = try container.decodeIfPresent(String.self, forKey: "organization_id")
      self.role = try container.decode(RestSchema.OrganizationRole.self, forKey: "role")
      self.sources = try container.decode([RestSchema.TileSource].self, forKey: "sources")
      self.updated_at = try container.decodeWired(Date.self, forKey: "updated_at")
    }

    /// Writes a `Collection` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.count, forKey: "count")
      try container.encodeWired(self.created_at, forKey: "created_at")
      try container.encode(self.created_by, forKey: "created_by")
      try container.encodeNullable(self.description, forKey: "description")
      try container.encode(self.etag, forKey: "etag")
      try container.encode(self.id, forKey: "id")
      try container.encode(self.is_private, forKey: "is_private")
      try container.encode(self.name, forKey: "name")
      try container.encodeNullable(self.organization_id, forKey: "organization_id")
      try container.encode(self.role, forKey: "role")
      try container.encode(self.sources, forKey: "sources")
      try container.encodeWired(self.updated_at, forKey: "updated_at")
    }
  }
}
