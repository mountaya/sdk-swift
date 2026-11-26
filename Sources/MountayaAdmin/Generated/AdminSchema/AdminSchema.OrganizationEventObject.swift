// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// An organization as a webhook event carries it: its identifier, its name and its
  /// version. `getOrganization` reads the rest.
  ///
  /// Every string it carries is bounded, and it carries no geometry, no file and no
  /// credential, so a payload stays small whatever the resource holds.
  public struct OrganizationEventObject: Sendable, Hashable, Codable {
    /// The kind of object this is, always `organization`: the family of the event types
    /// that carry it, and what tells the members of `WebhookEventObject` apart.
    ///
    /// It is always `organization`, the discriminator value naming this member of its union.
    public var object: String {
      "organization"
    }
    /// Identifier of the organization.
    public var id: String
    /// The organization's name.
    public var name: String
    /// The organization's version once this change was made. It climbs with every change
    /// a read of the organization shows, so of two events about one organization the one
    /// carrying the higher `version` is the later state: events are not delivered in
    /// order.
    public var version: Int64
    /// When the organization was created.
    public var created_at: Date
    /// When the organization's own fields last changed.
    public var updated_at: Date

    /// Creates a `OrganizationEventObject` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      id: String,
      name: String,
      version: Int64,
      created_at: Date,
      updated_at: Date,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.id = id
      self.name = name
      self.version = version
      self.created_at = created_at
      self.updated_at = updated_at
      configure(&self)
    }

    /// Reads a `OrganizationEventObject` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decode(String.self, forKey: "id")
      self.name = try container.decode(String.self, forKey: "name")
      self.version = try container.decode(Int64.self, forKey: "version")
      self.created_at = try container.decodeWired(Date.self, forKey: "created_at")
      self.updated_at = try container.decodeWired(Date.self, forKey: "updated_at")
    }

    /// Writes a `OrganizationEventObject` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.object, forKey: "object")
      try container.encode(self.id, forKey: "id")
      try container.encode(self.name, forKey: "name")
      try container.encode(self.version, forKey: "version")
      try container.encodeWired(self.created_at, forKey: "created_at")
      try container.encodeWired(self.updated_at, forKey: "updated_at")
    }
  }
}
