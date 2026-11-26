// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// An organization's subscription, as the billing operations report it. `api`
  /// is the metered Data API subscription, billed by the month on the Data API
  /// requests the organization makes, and the one subscription an
  /// operation in this contract opens: the organization's first saved card opens
  /// it, unless the customer, or that card, still owes an invoice, which is the
  /// `402` and opens nothing, and the organization holds `data` while it is in
  /// force. Opening billing
  /// opens nothing, so an organization has no summary at all until its first card
  /// has opened that subscription. One that has ended is still reported, with the
  /// status it ended on. What an organization's agreement with Mountaya grants,
  /// Map Studio, Map Publishing, the Tile API, Embedded Studio and White label, is
  /// not a subscription and is never reported here.
  public struct OrganizationSubscriptionSummary: Sendable, Hashable, Codable {
    /// The metered Data API subscription. It carries the Data API line, which
    /// bills the requests the organization makes, the MCP server's included,
    /// at the end of each billing period, a month counted from the day the
    /// subscription opened. A line's price says
    /// nothing a client should read a product from: `organization_capabilities`
    /// on `getMyOrganizations` says which products the organization holds. An
    /// organization that has never held one, as before its first card opens
    /// it, gets no summary at all rather than a summary without it. It is
    /// also where a Data API subscription Mountaya arranged separately for the
    /// organization is reported, which no operation in this contract opens:
    /// only such a one is read on a trial, billed by invoice, or with a line
    /// on the `tiles` dimension.
    public var api: AdminSchema.OrganizationSubscription?
    /// Whether the organization has a default payment method, which is what the
    /// metered use of the Data API needs: a key's Data API request answers
    /// `402` while the subscription is in force and no payment method is on
    /// file. It is what lets a client ask for a card before that happens. It
    /// says nothing about the subscription beside it: a default payment method
    /// can be on file while no subscription is in force, as when one has ended,
    /// and a card saved without becoming the default leaves it false. Present
    /// whenever a summary is returned. An organization that has never held a
    /// subscription gets no summary at all, whether or not it has saved a card:
    /// `getOrganizationBillingPaymentMethods` is the read for that.
    public var has_payment_method: Bool?

    /// Creates a `OrganizationSubscriptionSummary` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.api = nil
      self.has_payment_method = nil
      configure(&self)
    }

    /// Reads a `OrganizationSubscriptionSummary` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.api = try container.decodeIfPresent(
        AdminSchema.OrganizationSubscription.self, forKey: "api")
      self.has_payment_method = try container.decodeIfPresent(
        Bool.self, forKey: "has_payment_method")
    }

    /// Writes a `OrganizationSubscriptionSummary` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.api, forKey: "api")
      try container.encodeIfPresent(self.has_payment_method, forKey: "has_payment_method")
    }
  }
}
