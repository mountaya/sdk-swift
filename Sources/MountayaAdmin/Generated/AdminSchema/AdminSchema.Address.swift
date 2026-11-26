// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A postal billing address. The same shape on both sides of the exchange: it
  /// is what a read of the billing information returns and what an update sends,
  /// so a client reads one, edits a field and writes it back without reshaping it.
  /// Every field is optional, and an object whose fields are all empty clears the
  /// address.
  public struct Address: Sendable, Hashable, Codable {
    /// The street address, PO box or company name.
    public var line1: String?
    /// The apartment, suite, unit or building.
    public var line2: String?
    /// The city, district, suburb, town or village.
    public var city: String?
    /// The postal or ZIP code.
    public var postal_code: String?
    /// The state, county, province or region.
    public var state: String?
    /// The two-letter ISO 3166-1 alpha-2 country code. An empty value clears the
    /// country; any other value is exactly two characters.
    public var country: String?

    /// Creates a `Address` from the properties the contract requires, the optional ones being set
    /// in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.line1 = nil
      self.line2 = nil
      self.city = nil
      self.postal_code = nil
      self.state = nil
      self.country = nil
      configure(&self)
    }

    /// Reads a `Address` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.line1 = try container.decodeIfPresent(String.self, forKey: "line1")
      self.line2 = try container.decodeIfPresent(String.self, forKey: "line2")
      self.city = try container.decodeIfPresent(String.self, forKey: "city")
      self.postal_code = try container.decodeIfPresent(String.self, forKey: "postal_code")
      self.state = try container.decodeIfPresent(String.self, forKey: "state")
      self.country = try container.decodeIfPresent(String.self, forKey: "country")
    }

    /// Writes a `Address` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.line1, forKey: "line1")
      try container.encodeIfPresent(self.line2, forKey: "line2")
      try container.encodeIfPresent(self.city, forKey: "city")
      try container.encodeIfPresent(self.postal_code, forKey: "postal_code")
      try container.encodeIfPresent(self.state, forKey: "state")
      try container.encodeIfPresent(self.country, forKey: "country")
    }
  }
}
