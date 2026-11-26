// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// GetOrganizationWebhookHealthQuery is the query of `getOrganizationWebhookHealth`, one property
  /// to a parameter.
  public struct GetOrganizationWebhookHealthQuery: Sendable, Hashable {
    /// Keep only what concerns this webhook endpoint of the organization: one it
    /// holds, or one it deleted, whose deliveries stay readable for the 13 months
    /// they are kept. One that names no endpoint the organization held in those 13
    /// months is a `400` naming it. Omitted, every destination is covered, the
    /// notification emails included.
    public var webhook_endpoint_id: String?
    /// The window to report on, ending at the hour the request is answered in. Omitted
    /// with no range, it is `24h`; beside `start_at` or `end_at` it is a `400`.
    public var window: AdminSchema.WebhookHealthWindow?
    /// The first instant covered, inclusive, as an RFC 3339 date-time. Events and
    /// deliveries are kept 13 months, so an instant before that covers nothing
    /// more. A `start_at` after `end_at` is a `400` naming both.
    public var start_at: Date?
    /// The instant the range ends at, exclusive, as an RFC 3339 date-time.
    /// Omitted, the range runs to the moment the request is answered.
    public var end_at: Date?

    /// Creates a `GetOrganizationWebhookHealthQuery` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.webhook_endpoint_id = nil
      self.window = nil
      self.start_at = nil
      self.end_at = nil
      configure(&self)
    }

    /// items is the query, as the request carries it: one item to a value, in the operation's
    /// order, and none for a parameter left `nil`.
    var items: [QueryItem] {
      var items: [QueryItem] = []
      if let value = self.webhook_endpoint_id {
        items.append(.init(name: "webhook_endpoint_id", value: value))
      }
      if let value = self.window {
        items.append(.init(name: "window", value: value.rawValue))
      }
      if let value = self.start_at {
        items.append(.init(name: "start_at", value: Timestamp.string(from: value)))
      }
      if let value = self.end_at {
        items.append(.init(name: "end_at", value: Timestamp.string(from: value)))
      }
      return items
    }
  }
}
