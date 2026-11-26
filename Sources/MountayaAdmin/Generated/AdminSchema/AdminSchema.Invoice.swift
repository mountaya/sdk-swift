// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// An invoice on the organization's billing account, open or already settled.
  /// Amounts are in the currency's minor unit, for example cents. The two links
  /// are where the payer views and downloads the document, and neither is present
  /// while an invoice is still a draft. An organization billed by its agreement
  /// with Mountaya, or awaiting one, is given the PDF alone.
  public struct Invoice: Sendable, Hashable, Codable {
    /// Identifier of the invoice. Opaque, and issued by the payment provider
    /// rather than by Mountaya, so do not parse it as a UUID the way every `id`
    /// Mountaya issues can be.
    public var id: String
    /// The invoice number a payer quotes, for example `MTYA-0042`. Absent while
    /// the invoice is a draft and has not been numbered.
    public var number: String?
    /// When the invoice was raised.
    public var created_at: Date
    /// The invoice total, in the currency's minor unit.
    public var total: Int64
    /// What is still owed, in the currency's minor unit: zero once the invoice
    /// is paid, and on a void invoice, which nobody owes. An uncollectible
    /// invoice keeps what was left unpaid, and a draft carries what it will ask
    /// for once finalized.
    public var amount_due: Int64
    /// The three-letter ISO 4217 code the invoice is denominated in, for
    /// example `eur`.
    public var currency: String
    /// Where the invoice stands in its lifecycle.
    public var status: AdminSchema.InvoiceStatus
    /// A link the payer follows to view and settle the invoice online. Absent
    /// while the invoice is a draft, and on every invoice of an organization
    /// billed by its agreement with Mountaya, or awaiting one, which settles its
    /// invoices as the agreement says rather than online.
    public var hosted_invoice_url: URI?
    /// A link to the invoice as a PDF. Absent while the invoice is a draft.
    public var invoice_pdf: URI?

    /// Creates a `Invoice` from the properties the contract requires, the optional ones being set
    /// in `configure`.
    public init(
      id: String,
      created_at: Date,
      total: Int64,
      amount_due: Int64,
      currency: String,
      status: AdminSchema.InvoiceStatus,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.id = id
      self.number = nil
      self.created_at = created_at
      self.total = total
      self.amount_due = amount_due
      self.currency = currency
      self.status = status
      self.hosted_invoice_url = nil
      self.invoice_pdf = nil
      configure(&self)
    }

    /// Reads a `Invoice` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decode(String.self, forKey: "id")
      self.number = try container.decodeIfPresent(String.self, forKey: "number")
      self.created_at = try container.decodeWired(Date.self, forKey: "created_at")
      self.total = try container.decode(Int64.self, forKey: "total")
      self.amount_due = try container.decode(Int64.self, forKey: "amount_due")
      self.currency = try container.decode(String.self, forKey: "currency")
      self.status = try container.decode(AdminSchema.InvoiceStatus.self, forKey: "status")
      self.hosted_invoice_url = try container.decodeIfPresent(
        URI.self, forKey: "hosted_invoice_url")
      self.invoice_pdf = try container.decodeIfPresent(URI.self, forKey: "invoice_pdf")
    }

    /// Writes a `Invoice` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.id, forKey: "id")
      try container.encodeIfPresent(self.number, forKey: "number")
      try container.encodeWired(self.created_at, forKey: "created_at")
      try container.encode(self.total, forKey: "total")
      try container.encode(self.amount_due, forKey: "amount_due")
      try container.encode(self.currency, forKey: "currency")
      try container.encode(self.status, forKey: "status")
      try container.encodeIfPresent(self.hosted_invoice_url, forKey: "hosted_invoice_url")
      try container.encodeIfPresent(self.invoice_pdf, forKey: "invoice_pdf")
    }
  }
}
