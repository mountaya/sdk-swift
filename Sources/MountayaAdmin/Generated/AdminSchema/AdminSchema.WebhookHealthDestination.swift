// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// One destination's line of a webhook reliability report: an endpoint, or the
  /// organization's notification emails taken together.
  public struct WebhookHealthDestination: Sendable, Hashable, Codable {
    /// Which kind of destination the line is.
    public var destination: AdminSchema.WebhookDestinationKind
    /// Identifier of the endpoint, on an endpoint's line.
    public var webhook_endpoint_id: String?
    /// Whether Mountaya delivers to the endpoint, on an endpoint's line. Absent
    /// on the line of an endpoint the organization has deleted, which a report
    /// narrowed to it still carries.
    public var status: AdminSchema.WebhookEndpointStatus?
    /// When the endpoint's run of failed deliveries began, on an endpoint's
    /// line, null while its last delivery succeeded.
    public var failing_since: Date?
    /// When a delivery to the destination last succeeded. An endpoint's is
    /// its own last success, however long ago, and null when it never had
    /// one; the notification emails' is null when none succeeded in the 13
    /// months deliveries are kept.
    public var last_success_at: Date?
    /// The attempts made to the destination in the span.
    public var attempts_made: Int64
    /// The share of the destination's deliveries that succeeded at their first
    /// attempt, null when none was made.
    public var first_attempt_success_rate: Double?
    /// The share of the destination's deliveries settled in the span that
    /// succeeded, null when none settled.
    public var eventual_success_rate: Double?
    /// The destination's deliveries whose every attempt failed.
    public var deliveries_exhausted: Int64

    /// Creates a `WebhookHealthDestination` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      destination: AdminSchema.WebhookDestinationKind,
      last_success_at: Date?,
      attempts_made: Int64,
      first_attempt_success_rate: Double?,
      eventual_success_rate: Double?,
      deliveries_exhausted: Int64,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.destination = destination
      self.webhook_endpoint_id = nil
      self.status = nil
      self.failing_since = nil
      self.last_success_at = last_success_at
      self.attempts_made = attempts_made
      self.first_attempt_success_rate = first_attempt_success_rate
      self.eventual_success_rate = eventual_success_rate
      self.deliveries_exhausted = deliveries_exhausted
      configure(&self)
    }

    /// Reads a `WebhookHealthDestination` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.destination = try container.decode(
        AdminSchema.WebhookDestinationKind.self, forKey: "destination")
      self.webhook_endpoint_id = try container.decodeIfPresent(
        String.self, forKey: "webhook_endpoint_id")
      self.status = try container.decodeIfPresent(
        AdminSchema.WebhookEndpointStatus.self, forKey: "status")
      self.failing_since = try container.decodeWiredIfPresent(Date.self, forKey: "failing_since")
      self.last_success_at = try container.decodeWiredIfPresent(
        Date.self, forKey: "last_success_at")
      self.attempts_made = try container.decode(Int64.self, forKey: "attempts_made")
      self.first_attempt_success_rate = try container.decodeIfPresent(
        Double.self, forKey: "first_attempt_success_rate")
      self.eventual_success_rate = try container.decodeIfPresent(
        Double.self, forKey: "eventual_success_rate")
      self.deliveries_exhausted = try container.decode(Int64.self, forKey: "deliveries_exhausted")
    }

    /// Writes a `WebhookHealthDestination` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.destination, forKey: "destination")
      try container.encodeIfPresent(self.webhook_endpoint_id, forKey: "webhook_endpoint_id")
      try container.encodeIfPresent(self.status, forKey: "status")
      try container.encodeWiredIfPresent(self.failing_since, forKey: "failing_since")
      try container.encodeWiredNullable(self.last_success_at, forKey: "last_success_at")
      try container.encode(self.attempts_made, forKey: "attempts_made")
      try container.encodeNullable(
        self.first_attempt_success_rate, forKey: "first_attempt_success_rate")
      try container.encodeNullable(self.eventual_success_rate, forKey: "eventual_success_rate")
      try container.encode(self.deliveries_exhausted, forKey: "deliveries_exhausted")
    }
  }
}
