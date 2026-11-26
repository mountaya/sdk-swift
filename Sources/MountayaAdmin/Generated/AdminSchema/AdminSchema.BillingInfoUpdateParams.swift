// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A change to an organization's billing information. Every field is optional
  /// and every field present is a replacement, so a form that submits the whole
  /// record writes the whole record and one that submits a single group leaves the
  /// rest as it stands.
  ///
  /// What each field does when it is absent, present, or present and empty:
  /// - `name` absent leaves the invoicing name as it is. Present and empty
  ///   restores the organization's own name rather than clearing it, which is why
  ///   no minimum length is declared; any other value is at least two characters.
  /// - `email` absent leaves the invoicing address as it is.
  /// - `address` absent leaves the address as it is. An address object whose
  ///   fields are all empty clears it.
  /// - `tax_id` absent leaves the tax identifier as it is. A `tax_id` with an
  ///   empty value clears it, and one with a value replaces it.
  public struct BillingInfoUpdateParams: Sendable, Hashable, Codable {
    /// The name to address invoices to. Present and empty restores the
    /// organization's own name, which is why no minimum is declared: any OTHER
    /// value is at least two characters, and the empty string is the one way to
    /// ask for the default back. A minimum here would take that away from every
    /// generated client.
    public var name: String?
    /// The address to send invoices and payment notices to. Optional and not
    /// nullable: omit it to keep the current address.
    public var email: String?
    /// The billing address to write. Optional and not nullable: omit it to keep
    /// the address on file; an object whose fields are all empty clears it.
    public var address: AdminSchema.Address?
    /// The tax identifier to register. Optional and not nullable: omit it to keep
    /// the one on file; a `value` of the empty string clears it.
    public var tax_id: AdminSchema.BillingInfoTaxIdParams?

    /// Creates a `BillingInfoUpdateParams` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.name = nil
      self.email = nil
      self.address = nil
      self.tax_id = nil
      configure(&self)
    }

    /// Reads a `BillingInfoUpdateParams` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.name = try container.decodeIfPresent(String.self, forKey: "name")
      self.email = try container.decodeIfPresent(String.self, forKey: "email")
      self.address = try container.decodeIfPresent(AdminSchema.Address.self, forKey: "address")
      self.tax_id = try container.decodeIfPresent(
        AdminSchema.BillingInfoTaxIdParams.self, forKey: "tax_id")
    }

    /// Writes a `BillingInfoUpdateParams` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.name, forKey: "name")
      try container.encodeIfPresent(self.email, forKey: "email")
      try container.encodeIfPresent(self.address, forKey: "address")
      try container.encodeIfPresent(self.tax_id, forKey: "tax_id")
    }
  }
}
