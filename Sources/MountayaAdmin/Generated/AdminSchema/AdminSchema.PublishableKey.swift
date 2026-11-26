// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A publishable key: the credential a browser presents. It is safe to ship in
  /// a page, which is why what it reaches is narrowed by its scopes and why a
  /// `management` scope is never enough on its own.
  public struct PublishableKey: Sendable, Hashable, Codable {
    /// Timestamp of the publishable key's creation.
    public var created_at: Date
    /// The version of the key, the one the `ETag` of a read of it carries,
    /// opaque and compared whole. It moves on every change to the key's name
    /// or scopes and when it is revoked. Send it as `If-Match` to make
    /// `patchOrganizationPublishableKey` or `deleteOrganizationPublishableKey`
    /// conditional.
    public var etag: String
    /// Identifier of the key. It is what names the key on an update or a
    /// revocation, and is not the key itself.
    public var id: String
    /// The key value, the `pk_` token a client sends as `X-API-Key`. Always the
    /// `pk_` prefix followed by 32 lowercase hexadecimal characters, 35 in all,
    /// the shape every key is minted with. It is returned in full on every read,
    /// because a publishable key is meant to be seen.
    public var key: String
    /// Timestamp of the last request that presented this key, recorded at most
    /// once a minute, so it may trail the latest use by up to a minute. Absent on
    /// a key never used.
    public var last_used_at: Date?
    /// Display name of the publishable key.
    public var name: String
    /// Identifier of the organization the key belongs to.
    public var organization_id: String
    /// Timestamp of the key's revocation. Absent on a key still in force.
    public var revoked_at: Date?
    /// The scopes the key carries, each at most once, in the order
    /// `PublishableKeyScope` declares them whatever order they were sent in.
    /// A key in force carries at least one, and one carrying `management`
    /// carries no other. A revoked key lists what it carried
    /// when it was revoked, which can be none.
    /// The list is what the key was given and nothing more, so no scope appears
    /// because another is present. A scope stays listed when its product is
    /// later switched off for the organization, and answers `402` where it is
    /// used until the product returns.
    public var scopes: [AdminSchema.PublishableKeyScope]

    /// Creates a `PublishableKey` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      created_at: Date,
      etag: String,
      id: String,
      key: String,
      name: String,
      organization_id: String,
      scopes: [AdminSchema.PublishableKeyScope],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.created_at = created_at
      self.etag = etag
      self.id = id
      self.key = key
      self.last_used_at = nil
      self.name = name
      self.organization_id = organization_id
      self.revoked_at = nil
      self.scopes = scopes
      configure(&self)
    }

    /// Reads a `PublishableKey` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.created_at = try container.decodeWired(Date.self, forKey: "created_at")
      self.etag = try container.decode(String.self, forKey: "etag")
      self.id = try container.decode(String.self, forKey: "id")
      self.key = try container.decode(String.self, forKey: "key")
      self.last_used_at = try container.decodeWiredIfPresent(Date.self, forKey: "last_used_at")
      self.name = try container.decode(String.self, forKey: "name")
      self.organization_id = try container.decode(String.self, forKey: "organization_id")
      self.revoked_at = try container.decodeWiredIfPresent(Date.self, forKey: "revoked_at")
      self.scopes = try container.decode([AdminSchema.PublishableKeyScope].self, forKey: "scopes")
    }

    /// Writes a `PublishableKey` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeWired(self.created_at, forKey: "created_at")
      try container.encode(self.etag, forKey: "etag")
      try container.encode(self.id, forKey: "id")
      try container.encode(self.key, forKey: "key")
      try container.encodeWiredIfPresent(self.last_used_at, forKey: "last_used_at")
      try container.encode(self.name, forKey: "name")
      try container.encode(self.organization_id, forKey: "organization_id")
      try container.encodeWiredIfPresent(self.revoked_at, forKey: "revoked_at")
      try container.encode(self.scopes, forKey: "scopes")
    }
  }
}
