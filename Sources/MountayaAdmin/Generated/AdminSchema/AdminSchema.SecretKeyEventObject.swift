// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A secret key as a webhook event carries it: its identifiers, its name and the last
  /// four characters of its value, which is never carried. Secret keys are made, renamed
  /// and revoked signed in to Mountaya's web application, and this contract reads none.
  ///
  /// Every string it carries is bounded, and it carries no geometry, no file and no
  /// credential, so a payload stays small whatever the resource holds.
  public struct SecretKeyEventObject: Sendable, Hashable, Codable {
    /// The kind of object this is, always `organization.secret_key`: the family of the
    /// event types that carry it, and what tells the members of `WebhookEventObject`
    /// apart.
    ///
    /// It is always `organization.secret_key`, the discriminator value naming this member of its
    /// union.
    public var object: String {
      "organization.secret_key"
    }
    /// Identifier of the key.
    public var id: String
    /// Identifier of the organization the key belongs to.
    public var organization_id: String
    /// The key's name.
    public var name: String
    /// The last four characters of the key's value.
    public var suffix: String
    /// When the key was created.
    public var created_at: Date
    /// When the key was revoked. Present once it is.
    public var revoked_at: Date?

    /// Creates a `SecretKeyEventObject` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      id: String,
      organization_id: String,
      name: String,
      suffix: String,
      created_at: Date,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.id = id
      self.organization_id = organization_id
      self.name = name
      self.suffix = suffix
      self.created_at = created_at
      self.revoked_at = nil
      configure(&self)
    }

    /// Reads a `SecretKeyEventObject` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decode(String.self, forKey: "id")
      self.organization_id = try container.decode(String.self, forKey: "organization_id")
      self.name = try container.decode(String.self, forKey: "name")
      self.suffix = try container.decode(String.self, forKey: "suffix")
      self.created_at = try container.decodeWired(Date.self, forKey: "created_at")
      self.revoked_at = try container.decodeWiredIfPresent(Date.self, forKey: "revoked_at")
    }

    /// Writes a `SecretKeyEventObject` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.object, forKey: "object")
      try container.encode(self.id, forKey: "id")
      try container.encode(self.organization_id, forKey: "organization_id")
      try container.encode(self.name, forKey: "name")
      try container.encode(self.suffix, forKey: "suffix")
      try container.encodeWired(self.created_at, forKey: "created_at")
      try container.encodeWiredIfPresent(self.revoked_at, forKey: "revoked_at")
    }
  }
}
