// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// An invoice as a webhook event carries it: its identifier, its status and its amounts.
  /// The links to the invoice's page and document are never carried:
  /// `getOrganizationBillingInvoices` lists them.
  ///
  /// Every string it carries is bounded, and it carries no geometry, no file and no
  /// credential, so a payload stays small whatever the resource holds.
  public struct InvoiceEventObject: Sendable, Hashable, Codable {
    /// The kind of object this is, always `organization.billing.invoice`: the family of
    /// the event types that carry it, and what tells the members of `WebhookEventObject`
    /// apart.
    ///
    /// It is always `organization.billing.invoice`, the discriminator value naming this member of
    /// its union.
    public var object: String {
      "organization.billing.invoice"
    }
    /// Identifier of the invoice, as the payment provider issues it. It is not a UUID.
    public var id: String
    /// Identifier of the organization the invoice is addressed to.
    public var organization_id: String
    /// The invoice's status once this change was made.
    public var status: AdminSchema.InvoiceStatus
    /// The invoice's total, in the currency's minor unit.
    public var total: Int64
    /// What is left to pay, in the currency's minor unit.
    public var amount_due: Int64
    /// The invoice's currency, a lowercase ISO 4217 code.
    public var currency: String
    /// When the invoice was raised.
    public var created_at: Date

    /// Creates a `InvoiceEventObject` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      id: String,
      organization_id: String,
      status: AdminSchema.InvoiceStatus,
      total: Int64,
      amount_due: Int64,
      currency: String,
      created_at: Date,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.id = id
      self.organization_id = organization_id
      self.status = status
      self.total = total
      self.amount_due = amount_due
      self.currency = currency
      self.created_at = created_at
      configure(&self)
    }

    /// Reads a `InvoiceEventObject` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decode(String.self, forKey: "id")
      self.organization_id = try container.decode(String.self, forKey: "organization_id")
      self.status = try container.decode(AdminSchema.InvoiceStatus.self, forKey: "status")
      self.total = try container.decode(Int64.self, forKey: "total")
      self.amount_due = try container.decode(Int64.self, forKey: "amount_due")
      self.currency = try container.decode(String.self, forKey: "currency")
      self.created_at = try container.decodeWired(Date.self, forKey: "created_at")
    }

    /// Writes a `InvoiceEventObject` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.object, forKey: "object")
      try container.encode(self.id, forKey: "id")
      try container.encode(self.organization_id, forKey: "organization_id")
      try container.encode(self.status, forKey: "status")
      try container.encode(self.total, forKey: "total")
      try container.encode(self.amount_due, forKey: "amount_due")
      try container.encode(self.currency, forKey: "currency")
      try container.encodeWired(self.created_at, forKey: "created_at")
    }
  }
}
