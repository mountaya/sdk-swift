// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// The display details of a card. Only what a payer needs to recognize which
  /// card it is: the brand, the last four digits and the expiry. The card number
  /// itself is never carried by this contract.
  public struct PaymentMethodCard: Sendable, Hashable, Codable {
    /// The card brand, for example `visa`, `mastercard` or `amex`.
    public var brand: String
    /// The last four digits of the card number.
    public var last4: String
    /// The expiry month, 1 through 12.
    public var exp_month: Int64
    /// The expiry year, four digits.
    public var exp_year: Int64

    /// Creates a `PaymentMethodCard` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      brand: String,
      last4: String,
      exp_month: Int64,
      exp_year: Int64,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.brand = brand
      self.last4 = last4
      self.exp_month = exp_month
      self.exp_year = exp_year
      configure(&self)
    }

    /// Reads a `PaymentMethodCard` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.brand = try container.decode(String.self, forKey: "brand")
      self.last4 = try container.decode(String.self, forKey: "last4")
      self.exp_month = try container.decode(Int64.self, forKey: "exp_month")
      self.exp_year = try container.decode(Int64.self, forKey: "exp_year")
    }

    /// Writes a `PaymentMethodCard` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.brand, forKey: "brand")
      try container.encode(self.last4, forKey: "last4")
      try container.encode(self.exp_month, forKey: "exp_month")
      try container.encode(self.exp_year, forKey: "exp_year")
    }
  }
}
