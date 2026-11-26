// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A collection's share link as a webhook event carries it: the collection it opens and
  /// when its token was minted. The token itself is never carried: `getCollectionShareLink`
  /// reads it.
  ///
  /// Every string it carries is bounded, and it carries no geometry, no file and no
  /// credential, so a payload stays small whatever the resource holds.
  public struct CollectionShareLinkEventObject: Sendable, Hashable, Codable {
    /// The kind of object this is, always `collection.share_link`: the family of the
    /// event types that carry it, and what tells the members of `WebhookEventObject`
    /// apart.
    ///
    /// It is always `collection.share_link`, the discriminator value naming this member of its
    /// union.
    public var object: String {
      "collection.share_link"
    }
    /// Identifier of the collection the link opens.
    public var collection_id: String
    /// When the link's token was minted: when the link was created, or last rotated.
    public var created_at: Date

    /// Creates a `CollectionShareLinkEventObject` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      collection_id: String,
      created_at: Date,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.collection_id = collection_id
      self.created_at = created_at
      configure(&self)
    }

    /// Reads a `CollectionShareLinkEventObject` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.collection_id = try container.decode(String.self, forKey: "collection_id")
      self.created_at = try container.decodeWired(Date.self, forKey: "created_at")
    }

    /// Writes a `CollectionShareLinkEventObject` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.object, forKey: "object")
      try container.encode(self.collection_id, forKey: "collection_id")
      try container.encodeWired(self.created_at, forKey: "created_at")
    }
  }
}
