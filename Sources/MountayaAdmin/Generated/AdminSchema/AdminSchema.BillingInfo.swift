// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// The billing information held for an organization: the name and email an
  /// invoice is addressed to, the billing address, and the tax identifier when one
  /// is registered. The address is absent when none is on file, and so is the tax
  /// identifier.
  public struct BillingInfo: Sendable, Hashable, Codable {
    /// The name an invoice is addressed to. It starts as the organization's own
    /// name and is changed through the billing information update. Never empty:
    /// an update that sends an empty name restores the organization's own rather
    /// than clearing this. The ceiling is the update's hundred characters rather
    /// than the thirty an organization name is held to, because a payer is a
    /// legal entity and the two are not the same field.
    public var name: String
    /// The address invoices and payment notices are sent to. It starts as the
    /// email address of the member who opened billing, which on this API is the
    /// user the session token names on `postOrganizationBillingProvision`, and
    /// is changed through the billing information update.
    public var email: String
    /// The billing address. Absent when none is on file. While none is, saving
    /// a card fills it from the card's billing address, when the card carries
    /// one.
    public var address: AdminSchema.Address?
    /// The tax identifier registered against the account, such as an EU VAT
    /// number. Absent when none is registered.
    public var tax_id: AdminSchema.TaxId?

    /// Creates a `BillingInfo` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      name: String,
      email: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.name = name
      self.email = email
      self.address = nil
      self.tax_id = nil
      configure(&self)
    }

    /// Reads a `BillingInfo` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.name = try container.decode(String.self, forKey: "name")
      self.email = try container.decode(String.self, forKey: "email")
      self.address = try container.decodeIfPresent(AdminSchema.Address.self, forKey: "address")
      self.tax_id = try container.decodeIfPresent(AdminSchema.TaxId.self, forKey: "tax_id")
    }

    /// Writes a `BillingInfo` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.name, forKey: "name")
      try container.encode(self.email, forKey: "email")
      try container.encodeIfPresent(self.address, forKey: "address")
      try container.encodeIfPresent(self.tax_id, forKey: "tax_id")
    }
  }
}
