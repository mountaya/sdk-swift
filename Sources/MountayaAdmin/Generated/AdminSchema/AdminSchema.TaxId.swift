// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A tax identifier held against the organization's billing account, such as an
  /// EU VAT number. It is returned as it was registered: the value is what the
  /// organization entered, and the type says which register that value belongs to.
  public struct TaxId: Sendable, Hashable, Codable {
    /// Which register the value belongs to, `eu_vat` for an EU VAT number. When
    /// an update supplies a value and no type, the type is `eu_vat` rather than
    /// a refusal. The vocabulary is the payment provider's
    /// rather than this contract's, so what is declared here is the same length
    /// ceiling the update parameter declares.
    public var type: String
    /// The registration number, for example a VAT number. The same ceiling the
    /// update parameter declares, because it is the same value read back.
    public var value: String

    /// Creates a `TaxId` from the properties the contract requires, the optional ones being set in
    /// `configure`.
    public init(
      type: String,
      value: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.type = type
      self.value = value
      configure(&self)
    }

    /// Reads a `TaxId` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.type = try container.decode(String.self, forKey: "type")
      self.value = try container.decode(String.self, forKey: "value")
    }

    /// Writes a `TaxId` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
      try container.encode(self.value, forKey: "value")
    }
  }
}
