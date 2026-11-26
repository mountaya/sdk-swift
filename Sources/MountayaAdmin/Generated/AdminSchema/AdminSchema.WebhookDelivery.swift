// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// One delivery of a webhook event to one destination: one of the
  /// organization's endpoints, or a notification email to one person. It
  /// carries where it stands and its last attempt; `getOrganizationWebhookDelivery`
  /// reads every attempt.
  public struct WebhookDelivery: Sendable, Hashable, Codable {
    /// Identifier of the delivery.
    public var id: String
    /// Identifier of the event delivered, which `getOrganizationWebhookEvent`
    /// reads.
    public var event_id: String
    /// The type of the event delivered.
    public var event_type: AdminSchema.WebhookEventType
    /// Where the delivery goes.
    public var destination: AdminSchema.WebhookDestinationKind
    /// Identifier of the endpoint, on a delivery to an endpoint.
    public var webhook_endpoint_id: String?
    /// The person the email went to, on a notification email.
    public var recipient: AdminSchema.WebhookDeliveryRecipient?
    /// Which notification the email was, on a notification email.
    public var notification: AdminSchema.NotificationType?
    /// What started the delivery.
    public var trigger: AdminSchema.WebhookDeliveryTriggerKind
    /// Identifier of the resend, test or redelivery that started the delivery,
    /// the `id` `postOrganizationWebhookDelivery` answered. Absent when the event
    /// itself started it.
    public var trigger_id: String?
    /// Where the delivery stands.
    public var outcome: AdminSchema.WebhookDeliveryOutcome
    /// How many attempts were made, the canceled ones left out.
    public var attempt_count: Int
    /// When the last attempt was made. Absent before the first.
    public var last_attempt_at: Date?
    /// When the next attempt is due, null when none is: the delivery succeeded,
    /// was exhausted or canceled.
    public var next_attempt_at: Date?
    /// How the last attempt failed, present while that attempt is a failure.
    public var failure_kind: AdminSchema.WebhookFailureKind?
    /// Whose the last attempt's failure is, present beside `failure_kind`.
    public var failure_class: AdminSchema.WebhookFailureClass?
    /// The HTTP status the endpoint answered the last attempt with, on a
    /// delivery to an endpoint that answered at all.
    public var response_status: Int?
    /// When the delivery was started.
    public var created_at: Date

    /// Creates a `WebhookDelivery` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      id: String,
      event_id: String,
      event_type: AdminSchema.WebhookEventType,
      destination: AdminSchema.WebhookDestinationKind,
      trigger: AdminSchema.WebhookDeliveryTriggerKind,
      outcome: AdminSchema.WebhookDeliveryOutcome,
      attempt_count: Int,
      next_attempt_at: Date?,
      created_at: Date,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.id = id
      self.event_id = event_id
      self.event_type = event_type
      self.destination = destination
      self.webhook_endpoint_id = nil
      self.recipient = nil
      self.notification = nil
      self.trigger = trigger
      self.trigger_id = nil
      self.outcome = outcome
      self.attempt_count = attempt_count
      self.last_attempt_at = nil
      self.next_attempt_at = next_attempt_at
      self.failure_kind = nil
      self.failure_class = nil
      self.response_status = nil
      self.created_at = created_at
      configure(&self)
    }

    /// Reads a `WebhookDelivery` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decode(String.self, forKey: "id")
      self.event_id = try container.decode(String.self, forKey: "event_id")
      self.event_type = try container.decode(
        AdminSchema.WebhookEventType.self, forKey: "event_type")
      self.destination = try container.decode(
        AdminSchema.WebhookDestinationKind.self, forKey: "destination")
      self.webhook_endpoint_id = try container.decodeIfPresent(
        String.self, forKey: "webhook_endpoint_id")
      self.recipient = try container.decodeIfPresent(
        AdminSchema.WebhookDeliveryRecipient.self, forKey: "recipient")
      self.notification = try container.decodeIfPresent(
        AdminSchema.NotificationType.self, forKey: "notification")
      self.trigger = try container.decode(
        AdminSchema.WebhookDeliveryTriggerKind.self, forKey: "trigger")
      self.trigger_id = try container.decodeIfPresent(String.self, forKey: "trigger_id")
      self.outcome = try container.decode(
        AdminSchema.WebhookDeliveryOutcome.self, forKey: "outcome")
      self.attempt_count = try container.decode(Int.self, forKey: "attempt_count")
      self.last_attempt_at = try container.decodeWiredIfPresent(
        Date.self, forKey: "last_attempt_at")
      self.next_attempt_at = try container.decodeWiredIfPresent(
        Date.self, forKey: "next_attempt_at")
      self.failure_kind = try container.decodeIfPresent(
        AdminSchema.WebhookFailureKind.self, forKey: "failure_kind")
      self.failure_class = try container.decodeIfPresent(
        AdminSchema.WebhookFailureClass.self, forKey: "failure_class")
      self.response_status = try container.decodeIfPresent(Int.self, forKey: "response_status")
      self.created_at = try container.decodeWired(Date.self, forKey: "created_at")
    }

    /// Writes a `WebhookDelivery` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.id, forKey: "id")
      try container.encode(self.event_id, forKey: "event_id")
      try container.encode(self.event_type, forKey: "event_type")
      try container.encode(self.destination, forKey: "destination")
      try container.encodeIfPresent(self.webhook_endpoint_id, forKey: "webhook_endpoint_id")
      try container.encodeIfPresent(self.recipient, forKey: "recipient")
      try container.encodeIfPresent(self.notification, forKey: "notification")
      try container.encode(self.trigger, forKey: "trigger")
      try container.encodeIfPresent(self.trigger_id, forKey: "trigger_id")
      try container.encode(self.outcome, forKey: "outcome")
      try container.encode(self.attempt_count, forKey: "attempt_count")
      try container.encodeWiredIfPresent(self.last_attempt_at, forKey: "last_attempt_at")
      try container.encodeWiredNullable(self.next_attempt_at, forKey: "next_attempt_at")
      try container.encodeIfPresent(self.failure_kind, forKey: "failure_kind")
      try container.encodeIfPresent(self.failure_class, forKey: "failure_class")
      try container.encodeIfPresent(self.response_status, forKey: "response_status")
      try container.encodeWired(self.created_at, forKey: "created_at")
    }
  }
}
