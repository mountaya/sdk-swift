// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// What to deliver to one of the organization's endpoints, beside
  /// `webhook_endpoint_id`: exactly one of `event_id`, a resend of one event;
  /// `test`, a test event; or `since`, a redelivery of every event the endpoint
  /// was sent from an instant on. None of them, or more than one, is a `400`.
  public struct WebhookDeliveryCreateParams: Sendable, Hashable, Codable {
    /// Identifier of the endpoint to deliver to. A disabled one is a `409`:
    /// enable it first.
    public var webhook_endpoint_id: String
    /// A resend: the event to deliver again, recorded in the last 30 days,
    /// whether or not the endpoint was sent it the first time or its
    /// `enabled_events` names its type. It starts one delivery, its own
    /// attempts on the delivery schedule.
    public var event_id: String?
    /// A test: a test event of the type named, delivered once without retries.
    public var test: AdminSchema.WebhookDeliveryTestParams?
    /// A redelivery: every event recorded from this instant on, at most 30 days
    /// ago, whose type the endpoint's `enabled_events` names, delivered again
    /// oldest first at a paced rate, each its own delivery carrying the
    /// redelivery's `trigger_id`. An instant further back, or one still to
    /// come, is a `400` naming it.
    public var since: Date?

    /// Creates a `WebhookDeliveryCreateParams` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      webhook_endpoint_id: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.webhook_endpoint_id = webhook_endpoint_id
      self.event_id = nil
      self.test = nil
      self.since = nil
      configure(&self)
    }

    /// Reads a `WebhookDeliveryCreateParams` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.webhook_endpoint_id = try container.decode(String.self, forKey: "webhook_endpoint_id")
      self.event_id = try container.decodeIfPresent(String.self, forKey: "event_id")
      self.test = try container.decodeIfPresent(
        AdminSchema.WebhookDeliveryTestParams.self, forKey: "test")
      self.since = try container.decodeWiredIfPresent(Date.self, forKey: "since")
    }

    /// Writes a `WebhookDeliveryCreateParams` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.webhook_endpoint_id, forKey: "webhook_endpoint_id")
      try container.encodeIfPresent(self.event_id, forKey: "event_id")
      try container.encodeIfPresent(self.test, forKey: "test")
      try container.encodeWiredIfPresent(self.since, forKey: "since")
    }
  }
}
