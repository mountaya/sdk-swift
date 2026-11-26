// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Coarse classification of a geocoded place. Used both as a response field
  /// on Place (clients can render category-specific UI) and as the dimension
  /// along which PlaceCategoriesInput filters forward / reverse geocoding
  /// output.
  ///
  /// This is a different axis from GeocodeLayer, and a Place carries both: the layer
  /// is the scope the geocoder resolved to, this is the coarse kind of thing the
  /// result is. Only COUNTRY is spelled the same in both. Read them independently.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct PlaceCategory: RawRepresentable, Sendable, Hashable, Codable,
    CodingKeyRepresentable, ExpressibleByStringLiteral
  {
    /// Populated places like cities, towns, villages, hamlets, and suburbs.
    public static let populatedPlace: Self = "POPULATED_PLACE"
    /// Administrative boundaries like regions, counties, departments, districts, and localities.
    public static let administrativeArea: Self = "ADMINISTRATIVE_AREA"
    /// Country-level results such as France or Switzerland.
    public static let country: Self = "COUNTRY"
    /// Natural features like mountain peaks, lakes, glaciers, rivers, and forests.
    public static let naturalFeature: Self = "NATURAL_FEATURE"
    /// Transit stations like train stations, bus terminals, airports, and cable car stations.
    public static let transitStation: Self = "TRANSIT_STATION"
    /// Amenities like cafes, restaurants, shops, tourist attractions, and leisure venues.
    public static let amenity: Self = "AMENITY"
    /// Addresses like streets, house numbers, and postcodes.
    public static let address: Self = "ADDRESS"
    /// Catch-all for places that do not fit any of the other categories.
    public static let other: Self = "OTHER"

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
