// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A zone's membership of a collection: which collection and which zone.
  ///
  /// Every string it carries is bounded, and it carries no geometry, no file and no
  /// credential, so a payload stays small whatever the resource holds.
  public struct CollectionZoneEventObject: Sendable, Hashable, Codable {
    /// The kind of object this is, always `collection.zone`: the family of the event
    /// types that carry it, and what tells the members of `WebhookEventObject` apart.
    ///
    /// It is always `collection.zone`, the discriminator value naming this member of its union.
    public var object: String {
      "collection.zone"
    }
    /// Identifier of the collection.
    public var collection_id: String
    /// Identifier of the zone.
    public var zone_id: String
    /// The collection's `version` once this change was made, which every change to what
    /// it holds moves. Of two events about one collection, the one carrying the higher
    /// figure is the later state.
    public var collection_version: Int64

    /// Creates a `CollectionZoneEventObject` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      collection_id: String,
      zone_id: String,
      collection_version: Int64,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.collection_id = collection_id
      self.zone_id = zone_id
      self.collection_version = collection_version
      configure(&self)
    }

    /// Reads a `CollectionZoneEventObject` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.collection_id = try container.decode(String.self, forKey: "collection_id")
      self.zone_id = try container.decode(String.self, forKey: "zone_id")
      self.collection_version = try container.decode(Int64.self, forKey: "collection_version")
    }

    /// Writes a `CollectionZoneEventObject` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.object, forKey: "object")
      try container.encode(self.collection_id, forKey: "collection_id")
      try container.encode(self.zone_id, forKey: "zone_id")
      try container.encode(self.collection_version, forKey: "collection_version")
    }
  }
}
