// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A resend, a test or a redelivery `postOrganizationWebhookDelivery` started.
  /// The deliveries it starts run after the answer, and each carries its `id` as
  /// `trigger_id`, which `getOrganizationWebhookDeliveries` filters on.
  public struct WebhookDeliveryTrigger: Sendable, Hashable, Codable {
    /// Identifier of the resend, test or redelivery.
    public var id: String
    /// Which of the three it is.
    public var kind: AdminSchema.WebhookDeliveryTriggerKind
    /// Identifier of the endpoint it delivers to.
    public var webhook_endpoint_id: String
    /// The event resent, on a resend.
    public var event_id: String?
    /// The type of the test event, on a test.
    public var event_type: AdminSchema.WebhookEventType?
    /// The instant the redelivery starts from, on a redelivery.
    public var since: Date?
    /// The delivery a resend or a test started, which
    /// `getOrganizationWebhookDelivery` reads. Null on a redelivery, which
    /// starts one delivery per event as it goes.
    public var delivery_id: String?
    /// When it was asked for.
    public var created_at: Date

    /// Creates a `WebhookDeliveryTrigger` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      id: String,
      kind: AdminSchema.WebhookDeliveryTriggerKind,
      webhook_endpoint_id: String,
      delivery_id: String?,
      created_at: Date,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.id = id
      self.kind = kind
      self.webhook_endpoint_id = webhook_endpoint_id
      self.event_id = nil
      self.event_type = nil
      self.since = nil
      self.delivery_id = delivery_id
      self.created_at = created_at
      configure(&self)
    }

    /// Reads a `WebhookDeliveryTrigger` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decode(String.self, forKey: "id")
      self.kind = try container.decode(AdminSchema.WebhookDeliveryTriggerKind.self, forKey: "kind")
      self.webhook_endpoint_id = try container.decode(String.self, forKey: "webhook_endpoint_id")
      self.event_id = try container.decodeIfPresent(String.self, forKey: "event_id")
      self.event_type = try container.decodeIfPresent(
        AdminSchema.WebhookEventType.self, forKey: "event_type")
      self.since = try container.decodeWiredIfPresent(Date.self, forKey: "since")
      self.delivery_id = try container.decodeIfPresent(String.self, forKey: "delivery_id")
      self.created_at = try container.decodeWired(Date.self, forKey: "created_at")
    }

    /// Writes a `WebhookDeliveryTrigger` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.id, forKey: "id")
      try container.encode(self.kind, forKey: "kind")
      try container.encode(self.webhook_endpoint_id, forKey: "webhook_endpoint_id")
      try container.encodeIfPresent(self.event_id, forKey: "event_id")
      try container.encodeIfPresent(self.event_type, forKey: "event_type")
      try container.encodeWiredIfPresent(self.since, forKey: "since")
      try container.encodeNullable(self.delivery_id, forKey: "delivery_id")
      try container.encodeWired(self.created_at, forKey: "created_at")
    }
  }
}
