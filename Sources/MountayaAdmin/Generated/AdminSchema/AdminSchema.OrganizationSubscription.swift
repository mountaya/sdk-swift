// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// One of an organization's subscriptions, as a client reads it: where it
  /// stands, how it is paid for, what it bills, and when the current period ends.
  /// It is a read: no operation writes it directly. It changes as a consequence
  /// of the billing operations, for example when a card is saved.
  public struct OrganizationSubscription: Sendable, Hashable, Codable {
    /// Where the subscription stands. Read it with `paused` to know whether the
    /// capabilities it grants are in force: a subscription can read `active`
    /// while `paused` is true, and nothing it grants is in force then.
    public var status: AdminSchema.SubscriptionStatus
    /// How the subscription is paid for, which is what says whether adding a
    /// card changes anything about it.
    public var collection_method: AdminSchema.SubscriptionCollectionMethod
    /// The lowercase ISO 4217 code the subscription bills in, for example
    /// `eur`.
    public var currency: String
    /// What the subscription bills, one entry per line.
    public var items: [AdminSchema.OrganizationSubscriptionItem]
    /// When the current billing period closes. The Data API subscription bills
    /// by the month, so this is the end of the current month of usage, which
    /// is when the requests made in it are invoiced. While
    /// `cancel_at_period_end` is true, it is also when the subscription ends.
    public var current_period_end_at: Date
    /// Whether the subscription ends at `current_period_end_at`: its end was
    /// scheduled by `deleteOrganizationBillingSubscription`, or by the
    /// organization's agreement with Mountaya taking over its billing. It is
    /// still in force until then, so the capabilities it grants are unaffected
    /// while this is true, and the period is invoiced as usual when it closes.
    /// `postOrganizationBillingSubscription` takes the end back before then.
    public var cancel_at_period_end: Bool
    /// Whether billing is suspended. A paused subscription invoices nothing and
    /// suspends the capabilities it grants exactly as a canceled one does; the
    /// flag is here so a client can say that it was paused rather than
    /// canceled, which is a different thing to ask the payer to fix.
    public var paused: Bool
    /// The discount on this subscription: on the Data API subscription, the one
    /// the promotion code given to `postOrganizationBillingProvision` put on it
    /// when the organization's first card opened it. Absent when it carries none.
    public var discount: AdminSchema.SubscriptionDiscount?

    /// Creates a `OrganizationSubscription` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      status: AdminSchema.SubscriptionStatus,
      collection_method: AdminSchema.SubscriptionCollectionMethod,
      currency: String,
      items: [AdminSchema.OrganizationSubscriptionItem],
      current_period_end_at: Date,
      cancel_at_period_end: Bool,
      paused: Bool,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.status = status
      self.collection_method = collection_method
      self.currency = currency
      self.items = items
      self.current_period_end_at = current_period_end_at
      self.cancel_at_period_end = cancel_at_period_end
      self.paused = paused
      self.discount = nil
      configure(&self)
    }

    /// Reads a `OrganizationSubscription` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.status = try container.decode(AdminSchema.SubscriptionStatus.self, forKey: "status")
      self.collection_method = try container.decode(
        AdminSchema.SubscriptionCollectionMethod.self, forKey: "collection_method")
      self.currency = try container.decode(String.self, forKey: "currency")
      self.items = try container.decode(
        [AdminSchema.OrganizationSubscriptionItem].self, forKey: "items")
      self.current_period_end_at = try container.decodeWired(
        Date.self, forKey: "current_period_end_at")
      self.cancel_at_period_end = try container.decode(Bool.self, forKey: "cancel_at_period_end")
      self.paused = try container.decode(Bool.self, forKey: "paused")
      self.discount = try container.decodeIfPresent(
        AdminSchema.SubscriptionDiscount.self, forKey: "discount")
    }

    /// Writes a `OrganizationSubscription` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.status, forKey: "status")
      try container.encode(self.collection_method, forKey: "collection_method")
      try container.encode(self.currency, forKey: "currency")
      try container.encode(self.items, forKey: "items")
      try container.encodeWired(self.current_period_end_at, forKey: "current_period_end_at")
      try container.encode(self.cancel_at_period_end, forKey: "cancel_at_period_end")
      try container.encode(self.paused, forKey: "paused")
      try container.encodeIfPresent(self.discount, forKey: "discount")
    }
  }
}
