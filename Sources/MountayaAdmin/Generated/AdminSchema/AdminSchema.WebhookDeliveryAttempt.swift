// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// One attempt of a delivery: when it was due and made, how it ended, and
  /// what the endpoint answered. Nothing an attempt records names how Mountaya
  /// made it.
  public struct WebhookDeliveryAttempt: Sendable, Hashable, Codable {
    /// Which attempt it is, from 1, the `Mountaya-Delivery-Attempt` it was
    /// sent with.
    public var attempt: Int
    /// How the attempt ended.
    public var outcome: AdminSchema.WebhookAttemptOutcome
    /// How the attempt failed, present on a failed one.
    public var failure_kind: AdminSchema.WebhookFailureKind?
    /// Whose the failure is, present on a failed attempt.
    public var failure_class: AdminSchema.WebhookFailureClass?
    /// When the delivery schedule made the attempt due, a receiver's
    /// `Retry-After` included.
    public var scheduled_at: Date
    /// When the attempt was made, absent on one canceled before it was.
    public var attempted_at: Date?
    /// How long the endpoint took to answer, in milliseconds, on an attempt
    /// that reached it.
    public var duration_ms: Int?
    /// The HTTP status the endpoint answered, on an attempt it answered.
    public var response_status: Int?
    /// The first 2 KiB of the endpoint's answer, as it sent them, on an attempt
    /// it answered with a body. A notification email's attempt carries none.
    public var response_body: String?

    /// Creates a `WebhookDeliveryAttempt` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      attempt: Int,
      outcome: AdminSchema.WebhookAttemptOutcome,
      scheduled_at: Date,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.attempt = attempt
      self.outcome = outcome
      self.failure_kind = nil
      self.failure_class = nil
      self.scheduled_at = scheduled_at
      self.attempted_at = nil
      self.duration_ms = nil
      self.response_status = nil
      self.response_body = nil
      configure(&self)
    }

    /// Reads a `WebhookDeliveryAttempt` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.attempt = try container.decode(Int.self, forKey: "attempt")
      self.outcome = try container.decode(AdminSchema.WebhookAttemptOutcome.self, forKey: "outcome")
      self.failure_kind = try container.decodeIfPresent(
        AdminSchema.WebhookFailureKind.self, forKey: "failure_kind")
      self.failure_class = try container.decodeIfPresent(
        AdminSchema.WebhookFailureClass.self, forKey: "failure_class")
      self.scheduled_at = try container.decodeWired(Date.self, forKey: "scheduled_at")
      self.attempted_at = try container.decodeWiredIfPresent(Date.self, forKey: "attempted_at")
      self.duration_ms = try container.decodeIfPresent(Int.self, forKey: "duration_ms")
      self.response_status = try container.decodeIfPresent(Int.self, forKey: "response_status")
      self.response_body = try container.decodeIfPresent(String.self, forKey: "response_body")
    }

    /// Writes a `WebhookDeliveryAttempt` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.attempt, forKey: "attempt")
      try container.encode(self.outcome, forKey: "outcome")
      try container.encodeIfPresent(self.failure_kind, forKey: "failure_kind")
      try container.encodeIfPresent(self.failure_class, forKey: "failure_class")
      try container.encodeWired(self.scheduled_at, forKey: "scheduled_at")
      try container.encodeWiredIfPresent(self.attempted_at, forKey: "attempted_at")
      try container.encodeIfPresent(self.duration_ms, forKey: "duration_ms")
      try container.encodeIfPresent(self.response_status, forKey: "response_status")
      try container.encodeIfPresent(self.response_body, forKey: "response_body")
    }
  }
}
