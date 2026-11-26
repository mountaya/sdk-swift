// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// One point of a webhook reliability report's series: the figures of one hour
  /// or one day.
  public struct WebhookHealthPoint: Sendable, Hashable, Codable {
    /// The public events recorded, whether or not anything was sent them.
    public var events_recorded: Int64
    /// The attempts the delivery schedule made due.
    public var attempts_due: Int64
    /// The attempts made.
    public var attempts_made: Int64
    /// Mountaya's service availability: the share of the attempts due that
    /// were made on schedule with no failure of Mountaya's. A receiver's
    /// failure counts here as an attempt made; only a failure classed
    /// `mountaya` and an attempt made late lower it.
    public var availability: Double?
    /// The median time from an event being recorded to its first attempt, in
    /// milliseconds.
    public var dispatch_delay_p50_ms: Int64?
    /// The 95th percentile of the time from an event being recorded to its
    /// first attempt, in milliseconds.
    public var dispatch_delay_p95_ms: Int64?
    /// The share of the deliveries whose first attempt was made within 60
    /// seconds of the event.
    public var dispatched_within_60s: Double?
    /// The share of the deliveries that succeeded at their first attempt.
    public var first_attempt_success_rate: Double?
    /// The share of the deliveries settled in the span that succeeded, at any
    /// attempt.
    public var eventual_success_rate: Double?
    /// The median time an endpoint took to answer an attempt, in
    /// milliseconds. Notification emails are left out.
    public var response_time_p50_ms: Int64?
    /// The 95th percentile of the time an endpoint took to answer an attempt,
    /// in milliseconds. Notification emails are left out.
    public var response_time_p95_ms: Int64?
    /// The deliveries that succeeded.
    public var deliveries_succeeded: Int64
    /// The deliveries still unsettled at the end of the span: waiting for an
    /// attempt, or for a retry.
    public var deliveries_pending: Int64
    /// The deliveries whose every attempt failed.
    public var deliveries_exhausted: Int64
    /// The deliveries canceled because their endpoint was disabled or deleted.
    public var deliveries_canceled: Int64
    /// The failed attempts, one entry per kind that happened, the most frequent
    /// first.
    public var failures: [AdminSchema.WebhookHealthFailure]
    /// When the hour or the day the point covers begins, in UTC.
    public var start_at: Date

    /// Creates a `WebhookHealthPoint` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      events_recorded: Int64,
      attempts_due: Int64,
      attempts_made: Int64,
      availability: Double?,
      dispatch_delay_p50_ms: Int64?,
      dispatch_delay_p95_ms: Int64?,
      dispatched_within_60s: Double?,
      first_attempt_success_rate: Double?,
      eventual_success_rate: Double?,
      response_time_p50_ms: Int64?,
      response_time_p95_ms: Int64?,
      deliveries_succeeded: Int64,
      deliveries_pending: Int64,
      deliveries_exhausted: Int64,
      deliveries_canceled: Int64,
      failures: [AdminSchema.WebhookHealthFailure],
      start_at: Date,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.events_recorded = events_recorded
      self.attempts_due = attempts_due
      self.attempts_made = attempts_made
      self.availability = availability
      self.dispatch_delay_p50_ms = dispatch_delay_p50_ms
      self.dispatch_delay_p95_ms = dispatch_delay_p95_ms
      self.dispatched_within_60s = dispatched_within_60s
      self.first_attempt_success_rate = first_attempt_success_rate
      self.eventual_success_rate = eventual_success_rate
      self.response_time_p50_ms = response_time_p50_ms
      self.response_time_p95_ms = response_time_p95_ms
      self.deliveries_succeeded = deliveries_succeeded
      self.deliveries_pending = deliveries_pending
      self.deliveries_exhausted = deliveries_exhausted
      self.deliveries_canceled = deliveries_canceled
      self.failures = failures
      self.start_at = start_at
      configure(&self)
    }

    /// Reads a `WebhookHealthPoint` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.events_recorded = try container.decode(Int64.self, forKey: "events_recorded")
      self.attempts_due = try container.decode(Int64.self, forKey: "attempts_due")
      self.attempts_made = try container.decode(Int64.self, forKey: "attempts_made")
      self.availability = try container.decodeIfPresent(Double.self, forKey: "availability")
      self.dispatch_delay_p50_ms = try container.decodeIfPresent(
        Int64.self, forKey: "dispatch_delay_p50_ms")
      self.dispatch_delay_p95_ms = try container.decodeIfPresent(
        Int64.self, forKey: "dispatch_delay_p95_ms")
      self.dispatched_within_60s = try container.decodeIfPresent(
        Double.self, forKey: "dispatched_within_60s")
      self.first_attempt_success_rate = try container.decodeIfPresent(
        Double.self, forKey: "first_attempt_success_rate")
      self.eventual_success_rate = try container.decodeIfPresent(
        Double.self, forKey: "eventual_success_rate")
      self.response_time_p50_ms = try container.decodeIfPresent(
        Int64.self, forKey: "response_time_p50_ms")
      self.response_time_p95_ms = try container.decodeIfPresent(
        Int64.self, forKey: "response_time_p95_ms")
      self.deliveries_succeeded = try container.decode(Int64.self, forKey: "deliveries_succeeded")
      self.deliveries_pending = try container.decode(Int64.self, forKey: "deliveries_pending")
      self.deliveries_exhausted = try container.decode(Int64.self, forKey: "deliveries_exhausted")
      self.deliveries_canceled = try container.decode(Int64.self, forKey: "deliveries_canceled")
      self.failures = try container.decode(
        [AdminSchema.WebhookHealthFailure].self, forKey: "failures")
      self.start_at = try container.decodeWired(Date.self, forKey: "start_at")
    }

    /// Writes a `WebhookHealthPoint` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.events_recorded, forKey: "events_recorded")
      try container.encode(self.attempts_due, forKey: "attempts_due")
      try container.encode(self.attempts_made, forKey: "attempts_made")
      try container.encodeNullable(self.availability, forKey: "availability")
      try container.encodeNullable(self.dispatch_delay_p50_ms, forKey: "dispatch_delay_p50_ms")
      try container.encodeNullable(self.dispatch_delay_p95_ms, forKey: "dispatch_delay_p95_ms")
      try container.encodeNullable(self.dispatched_within_60s, forKey: "dispatched_within_60s")
      try container.encodeNullable(
        self.first_attempt_success_rate, forKey: "first_attempt_success_rate")
      try container.encodeNullable(self.eventual_success_rate, forKey: "eventual_success_rate")
      try container.encodeNullable(self.response_time_p50_ms, forKey: "response_time_p50_ms")
      try container.encodeNullable(self.response_time_p95_ms, forKey: "response_time_p95_ms")
      try container.encode(self.deliveries_succeeded, forKey: "deliveries_succeeded")
      try container.encode(self.deliveries_pending, forKey: "deliveries_pending")
      try container.encode(self.deliveries_exhausted, forKey: "deliveries_exhausted")
      try container.encode(self.deliveries_canceled, forKey: "deliveries_canceled")
      try container.encode(self.failures, forKey: "failures")
      try container.encodeWired(self.start_at, forKey: "start_at")
    }
  }
}
