// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// The tax identifier to write with a billing information update. The type is
  /// optional and resolves to `eu_vat` when omitted; any other type the payment
  /// provider recognizes is registered as given. An empty value clears whatever
  /// tax identifier is on file.
  public struct BillingInfoTaxIdParams: Sendable, Hashable, Codable {
    /// The registration number, for example a VAT number. An empty string
    /// clears the tax identifier already on file.
    public var value: String
    /// Which register the value belongs to. Optional, and resolves to `eu_vat`
    /// when omitted. The vocabulary is the payment provider's rather than this
    /// contract's, so what is declared here is the length ceiling; a type the
    /// provider does not recognize is refused with a `400`.
    public var type: String?

    /// Creates a `BillingInfoTaxIdParams` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      value: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.value = value
      self.type = nil
      configure(&self)
    }

    /// Reads a `BillingInfoTaxIdParams` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.value = try container.decode(String.self, forKey: "value")
      self.type = try container.decodeIfPresent(String.self, forKey: "type")
    }

    /// Writes a `BillingInfoTaxIdParams` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.value, forKey: "value")
      try container.encodeIfPresent(self.type, forKey: "type")
    }
  }
}
