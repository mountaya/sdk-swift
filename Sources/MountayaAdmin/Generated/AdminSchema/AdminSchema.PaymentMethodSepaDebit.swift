// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// The display details of a SEPA Direct Debit mandate. Only what a payer needs
  /// to recognize which account it is: the last four characters of the IBAN, the
  /// country the account is held in, and the bank and branch codes when they are
  /// known. The IBAN itself is never carried by this contract.
  public struct PaymentMethodSepaDebit: Sendable, Hashable, Codable {
    /// The last four characters of the IBAN.
    public var last4: String
    /// The two-letter ISO 3166-1 alpha-2 code of the country the account is
    /// held in. Always exactly two characters here, unlike the country on a
    /// billing address, which an update may send empty to clear.
    public var country: String
    /// The code identifying the bank holding the account.
    public var bank_code: String?
    /// The code identifying the branch holding the account.
    public var branch_code: String?

    /// Creates a `PaymentMethodSepaDebit` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      last4: String,
      country: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.last4 = last4
      self.country = country
      self.bank_code = nil
      self.branch_code = nil
      configure(&self)
    }

    /// Reads a `PaymentMethodSepaDebit` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.last4 = try container.decode(String.self, forKey: "last4")
      self.country = try container.decode(String.self, forKey: "country")
      self.bank_code = try container.decodeIfPresent(String.self, forKey: "bank_code")
      self.branch_code = try container.decodeIfPresent(String.self, forKey: "branch_code")
    }

    /// Writes a `PaymentMethodSepaDebit` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.last4, forKey: "last4")
      try container.encode(self.country, forKey: "country")
      try container.encodeIfPresent(self.bank_code, forKey: "bank_code")
      try container.encodeIfPresent(self.branch_code, forKey: "branch_code")
    }
  }
}
