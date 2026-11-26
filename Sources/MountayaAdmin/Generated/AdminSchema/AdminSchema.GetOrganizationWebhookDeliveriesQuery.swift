// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// GetOrganizationWebhookDeliveriesQuery is the query of `getOrganizationWebhookDeliveries`, one
  /// property to a parameter.
  public struct GetOrganizationWebhookDeliveriesQuery: Sendable, Hashable, PagedQuery {
    /// Where the page starts: the `next_cursor` the previous page reported at
    /// `extensions.metadata.pagination`, sent back unchanged. Omitted, the listing
    /// starts at its first item.
    ///
    /// A cursor is opaque: it is not an offset and not an identifier, and a client
    /// never builds or edits one, and it is never longer than 1024 characters. It
    /// is bound to the operation that issued it, to its filters and its `sort`,
    /// and to the scope it listed, such as the organization or the collection in
    /// the path or the key's own organization. On `getItineraries`, `getZones`
    /// and `getCollections`, whose scope `organization_id` may leave implicit, it
    /// is bound as well to the tier of the credential it was issued to, a key
    /// alone (or with a session token minted without `user_id`, which reads as
    /// one) or a key with a session token naming a member. The next page is asked
    /// for the same way. A cursor sent to another operation, with different
    /// filters, a different `sort`, another scope or, on those three, another tier
    /// of credential, or altered in any way, is a `400` at
    /// `["request", "query", "cursor"]`. On every listing, each page applies the
    /// read tier of the credential that asks for it. Paging is by position in the
    /// sort order rather than by count, so an item whose sort key does not change
    /// is never skipped or served twice, whatever is created or deleted between
    /// two pages.
    public var cursor: String?
    /// How many items one page holds, between 1 and 100; 50 when omitted, on every
    /// listing that pages. `extensions.metadata.pagination.limit` reports the size
    /// the page was served at. A page shorter than `limit` is not how the end is
    /// told: the end is a `next_cursor` of `null`. The page is cut after
    /// authorization, so it never widens what a caller can read.
    public var limit: Int?
    /// Keep only what concerns this webhook endpoint of the organization: one it
    /// holds, or one it deleted, whose deliveries stay readable for the 13 months
    /// they are kept. One that names no endpoint the organization held in those 13
    /// months is a `400` naming it. Omitted, every destination is covered, the
    /// notification emails included.
    public var webhook_endpoint_id: String?
    /// Keep only the deliveries of this event, by the `id`
    /// `getOrganizationWebhookEvents` lists: every one of them, where
    /// `getOrganizationWebhookEvent` carries the 100 most recently started.
    public var event_id: String?
    /// Keep only the deliveries to this kind of destination: `email` keeps the
    /// notification emails.
    public var destination: AdminSchema.WebhookDestinationKind?
    /// Keep only the deliveries standing so.
    public var outcome: AdminSchema.WebhookDeliveryOutcome?
    /// Keep only the deliveries whose last attempt failed, and whose failure is this
    /// one's.
    public var failure_class: AdminSchema.WebhookFailureClass?
    /// Keep only the deliveries whose last attempt failed this way.
    public var failure_kind: AdminSchema.WebhookFailureKind?
    /// Keep only the deliveries of events of this type.
    public var event_type: AdminSchema.WebhookEventType?
    /// Keep only the deliveries one resend, test or redelivery started, by the `id`
    /// `postOrganizationWebhookDelivery` answered.
    public var trigger_id: String?
    /// The first instant covered, inclusive, as an RFC 3339 date-time. Events and
    /// deliveries are kept 13 months, so an instant before that covers nothing
    /// more. A `start_at` after `end_at` is a `400` naming both.
    public var start_at: Date?
    /// The instant the range ends at, exclusive, as an RFC 3339 date-time.
    /// Omitted, the range runs to the moment the request is answered.
    public var end_at: Date?

    /// Creates a `GetOrganizationWebhookDeliveriesQuery` from the properties the contract requires,
    /// the optional ones being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.cursor = nil
      self.limit = nil
      self.webhook_endpoint_id = nil
      self.event_id = nil
      self.destination = nil
      self.outcome = nil
      self.failure_class = nil
      self.failure_kind = nil
      self.event_type = nil
      self.trigger_id = nil
      self.start_at = nil
      self.end_at = nil
      configure(&self)
    }

    /// items is the query, as the request carries it: one item to a value, in the operation's
    /// order, and none for a parameter left `nil`.
    var items: [QueryItem] {
      var items: [QueryItem] = []
      if let value = self.cursor {
        items.append(.init(name: "cursor", value: value))
      }
      if let value = self.limit {
        items.append(.init(name: "limit", value: String(value)))
      }
      if let value = self.webhook_endpoint_id {
        items.append(.init(name: "webhook_endpoint_id", value: value))
      }
      if let value = self.event_id {
        items.append(.init(name: "event_id", value: value))
      }
      if let value = self.destination {
        items.append(.init(name: "destination", value: value.rawValue))
      }
      if let value = self.outcome {
        items.append(.init(name: "outcome", value: value.rawValue))
      }
      if let value = self.failure_class {
        items.append(.init(name: "failure_class", value: value.rawValue))
      }
      if let value = self.failure_kind {
        items.append(.init(name: "failure_kind", value: value.rawValue))
      }
      if let value = self.event_type {
        items.append(.init(name: "event_type", value: value.rawValue))
      }
      if let value = self.trigger_id {
        items.append(.init(name: "trigger_id", value: value))
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
