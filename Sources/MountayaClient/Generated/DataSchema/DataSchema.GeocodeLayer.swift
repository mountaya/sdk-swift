// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Geocoding result layer. Indicates the administrative or feature scope of a
  /// geocoded place, ordered from coarsest (country) to finest (house, natural
  /// feature).
  ///
  /// This is a different axis from PlaceCategory, and a Place carries both. The layer
  /// is the scope the geocoder resolved to and is what `layers` filters on; the
  /// category is the coarse kind of thing the result is and is what
  /// PlaceCategoriesInput filters on. Only COUNTRY is spelled the same in both, and
  /// even there the two answer different questions. Read them independently.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct GeocodeLayer: RawRepresentable, Sendable, Hashable, Codable, CodingKeyRepresentable,
    ExpressibleByStringLiteral
  {
    /// Country-level administrative boundary.
    public static let country: Self = "COUNTRY"
    /// Region or state within a country.
    public static let region: Self = "REGION"
    /// County or department within a region.
    public static let county: Self = "COUNTY"
    /// City, town, or village.
    public static let city: Self = "CITY"
    /// District or neighborhood within a city.
    public static let district: Self = "DISTRICT"
    /// Postal code area.
    public static let postcode: Self = "POSTCODE"
    /// Street or road.
    public static let street: Self = "STREET"
    /// House or building address.
    public static let house: Self = "HOUSE"
    /// Point of interest.
    public static let poi: Self = "POI"
    /// Natural feature such as a mountain, lake, or forest.
    public static let natural: Self = "NATURAL"

    /// rawValue is the value as the wire spells it.
    public let rawValue: String

    /// Creates a value from its wire spelling, which may be one this build has never seen.
    public init(rawValue: String) {
      self.rawValue = rawValue
    }

    /// Creates a value from a string literal, which is its wire spelling.
    public init(stringLiteral value: String) {
      self.rawValue = value
    }

    /// codingKey is the value as an object's key, where the contract keys a map by it.
    public var codingKey: any CodingKey {
      WireKey(stringValue: rawValue)
    }

    /// Creates a value from an object's key.
    public init?<Key: CodingKey>(codingKey: Key) {
      self.rawValue = codingKey.stringValue
    }

    /// Reads the value from its wire spelling.
    public init(from decoder: any Decoder) throws {
      self.rawValue = try decoder.singleValueContainer().decode(String.self)
    }

    /// Writes the value as the wire spells it.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.singleValueContainer()
      try container.encode(rawValue)
    }
  }
}
