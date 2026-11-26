// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// The reliability of an organization's webhooks over a span of time: Mountaya's
  /// service availability apart from each endpoint's success, as totals, as a
  /// series of hours or days, and one line per destination. It covers the
  /// organization's endpoints and its notification emails, or one endpoint.
  public struct WebhookHealth: Sendable, Hashable, Codable {
    /// The endpoint the report is narrowed to, when it is.
    public var webhook_endpoint_id: String?
    /// The first instant the report covers, inclusive.
    public var start_at: Date
    /// The instant the report ends at, exclusive.
    public var end_at: Date
    /// How long each point of `series` covers.
    public var granularity: AdminSchema.WebhookHealthGranularity
    /// The figures of the whole span.
    public var totals: AdminSchema.WebhookHealthFigures
    /// The figures of each hour or day of the span, oldest first, every one of
    /// them present, an empty one with zero counts and null rates.
    public var series: [AdminSchema.WebhookHealthPoint]
    /// One line per destination: each endpoint of the organization, or the one
    /// endpoint the report is narrowed to, and the notification emails, on a
    /// report that is not narrowed.
    public var destinations: [AdminSchema.WebhookHealthDestination]

    /// Creates a `WebhookHealth` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      start_at: Date,
      end_at: Date,
      granularity: AdminSchema.WebhookHealthGranularity,
      totals: AdminSchema.WebhookHealthFigures,
      series: [AdminSchema.WebhookHealthPoint],
      destinations: [AdminSchema.WebhookHealthDestination],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.webhook_endpoint_id = nil
      self.start_at = start_at
      self.end_at = end_at
      self.granularity = granularity
      self.totals = totals
      self.series = series
      self.destinations = destinations
      configure(&self)
    }

    /// Reads a `WebhookHealth` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.webhook_endpoint_id = try container.decodeIfPresent(
        String.self, forKey: "webhook_endpoint_id")
      self.start_at = try container.decodeWired(Date.self, forKey: "start_at")
      self.end_at = try container.decodeWired(Date.self, forKey: "end_at")
      self.granularity = try container.decode(
        AdminSchema.WebhookHealthGranularity.self, forKey: "granularity")
      self.totals = try container.decode(AdminSchema.WebhookHealthFigures.self, forKey: "totals")
      self.series = try container.decode([AdminSchema.WebhookHealthPoint].self, forKey: "series")
      self.destinations = try container.decode(
        [AdminSchema.WebhookHealthDestination].self, forKey: "destinations")
    }

    /// Writes a `WebhookHealth` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.webhook_endpoint_id, forKey: "webhook_endpoint_id")
      try container.encodeWired(self.start_at, forKey: "start_at")
      try container.encodeWired(self.end_at, forKey: "end_at")
      try container.encode(self.granularity, forKey: "granularity")
      try container.encode(self.totals, forKey: "totals")
      try container.encode(self.series, forKey: "series")
      try container.encode(self.destinations, forKey: "destinations")
    }
  }
}
