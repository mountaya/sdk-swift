// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A collection as a webhook event carries it: its identifiers, its name and description,
  /// whether it is private, and its version. `getCollection` reads the itineraries and
  /// zones it holds.
  ///
  /// Every string it carries is bounded, and it carries no geometry, no file and no
  /// credential, so a payload stays small whatever the resource holds.
  public struct CollectionEventObject: Sendable, Hashable, Codable {
    /// The kind of object this is, always `collection`: the family of the event types
    /// that carry it, and what tells the members of `WebhookEventObject` apart.
    ///
    /// It is always `collection`, the discriminator value naming this member of its union.
    public var object: String {
      "collection"
    }
    /// Identifier of the collection.
    public var id: String
    /// Identifier of the organization the collection belongs to.
    public var organization_id: String
    /// The collection's name.
    public var name: String
    /// The collection's description, null when it has none.
    public var description: String?
    /// Whether the collection is private to the organization.
    public var is_private: Bool
    /// The collection's version once this change was made. It climbs with every change a
    /// read of the collection shows, so of two events about one collection the one
    /// carrying the higher `version` is the later state: events are not delivered in
    /// order. A delete is the collection's last version change: `collection.deleted`
    /// carries the version one past the last the collection held, so an event about it
    /// that arrives after its delete is never the later state.
    public var version: Int64
    /// The user who created the collection.
    public var created_by: RestSchema.RelationToUser
    /// When the collection was created.
    public var created_at: Date
    /// When the collection last changed.
    public var updated_at: Date

    /// Creates a `CollectionEventObject` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      id: String,
      organization_id: String,
      name: String,
      description: String?,
      is_private: Bool,
      version: Int64,
      created_by: RestSchema.RelationToUser,
      created_at: Date,
      updated_at: Date,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.id = id
      self.organization_id = organization_id
      self.name = name
      self.description = description
      self.is_private = is_private
      self.version = version
      self.created_by = created_by
      self.created_at = created_at
      self.updated_at = updated_at
      configure(&self)
    }

    /// Reads a `CollectionEventObject` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decode(String.self, forKey: "id")
      self.organization_id = try container.decode(String.self, forKey: "organization_id")
      self.name = try container.decode(String.self, forKey: "name")
      self.description = try container.decodeIfPresent(String.self, forKey: "description")
      self.is_private = try container.decode(Bool.self, forKey: "is_private")
      self.version = try container.decode(Int64.self, forKey: "version")
      self.created_by = try container.decode(RestSchema.RelationToUser.self, forKey: "created_by")
      self.created_at = try container.decodeWired(Date.self, forKey: "created_at")
      self.updated_at = try container.decodeWired(Date.self, forKey: "updated_at")
    }

    /// Writes a `CollectionEventObject` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.object, forKey: "object")
      try container.encode(self.id, forKey: "id")
      try container.encode(self.organization_id, forKey: "organization_id")
      try container.encode(self.name, forKey: "name")
      try container.encodeNullable(self.description, forKey: "description")
      try container.encode(self.is_private, forKey: "is_private")
      try container.encode(self.version, forKey: "version")
      try container.encode(self.created_by, forKey: "created_by")
      try container.encodeWired(self.created_at, forKey: "created_at")
      try container.encodeWired(self.updated_at, forKey: "updated_at")
    }
  }
}
