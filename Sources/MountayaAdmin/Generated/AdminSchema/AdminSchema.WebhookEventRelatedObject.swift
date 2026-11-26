// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// The object a webhook event is about, as a type and an identifier, so a receiver routes
  /// the event before it reads `data`.
  public struct WebhookEventRelatedObject: Sendable, Hashable, Codable {
    /// The family of the event's type, which is the `object` of `data.object` too:
    /// `organization.member` for `organization.member.updated`.
    public var type: String
    /// The identifier a read of the object takes: `data.object.id` for most kinds; a
    /// member's `user_id`; for a share link, the itinerary's or the collection's; for an
    /// itinerary or a zone of a collection, the itinerary's or the zone's; and for an
    /// organization's settings, entitlements, AI provider configuration and billing
    /// information, the organization's. A Data API subscription's, an invoice's and a
    /// payment method's are the payment provider's, and are not UUIDs.
    public var id: String

    /// Creates a `WebhookEventRelatedObject` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      type: String,
      id: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.type = type
      self.id = id
      configure(&self)
    }

    /// Reads a `WebhookEventRelatedObject` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.type = try container.decode(String.self, forKey: "type")
      self.id = try container.decode(String.self, forKey: "id")
    }

    /// Writes a `WebhookEventRelatedObject` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
      try container.encode(self.id, forKey: "id")
    }
  }
}
