// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A public webhook event type, as `getWebhookEventTypes` lists it.
  public struct WebhookEventCatalogEntry: Sendable, Hashable, Codable {
    /// The event type.
    public var type: AdminSchema.WebhookEventType
    /// The type's family: the type without what happened, which names the kind
    /// of object `data.object` holds. `enabled_events` takes a family followed
    /// by `.*` for every type of it.
    public var family: String
    /// What happened, in one line of at most 120 characters.
    public var summary: String
    /// When the event is recorded, as this document's entry for the type says.
    /// Mountaya writes it rather than an organization, so the 100-character
    /// ceiling of a description an organization writes does not apply to it;
    /// it holds at most 2000 characters.
    public var description: String

    /// Creates a `WebhookEventCatalogEntry` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      type: AdminSchema.WebhookEventType,
      family: String,
      summary: String,
      description: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.type = type
      self.family = family
      self.summary = summary
      self.description = description
      configure(&self)
    }

    /// Reads a `WebhookEventCatalogEntry` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.type = try container.decode(AdminSchema.WebhookEventType.self, forKey: "type")
      self.family = try container.decode(String.self, forKey: "family")
      self.summary = try container.decode(String.self, forKey: "summary")
      self.description = try container.decode(String.self, forKey: "description")
    }

    /// Writes a `WebhookEventCatalogEntry` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
      try container.encode(self.family, forKey: "family")
      try container.encode(self.summary, forKey: "summary")
      try container.encode(self.description, forKey: "description")
    }
  }
}
