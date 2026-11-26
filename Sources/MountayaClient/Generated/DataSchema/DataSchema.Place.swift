// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// A single geocoded place result. Coordinates are GeoJSON-shaped arrays
  /// (longitude before latitude).
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct Place: Sendable, Hashable, Codable {
    /// Reference to the underlying OpenStreetMap feature.
    public var osm: DataSchema.OSMRef?
    /// Localized display name.
    public var name: String?
    /// Single-line label built from the house number and street, the city (or the
    /// district when there is no city), the region and the country, in that order,
    /// leaving out any the place does not carry.
    public var label: String?
    /// Canonical geocoding layer for this place.
    public var layer: DataSchema.GeocodeLayer?
    /// Canonical category for this place. Drives category-specific UI and is the
    /// dimension along which PlaceCategoriesInput filters geocoding output.
    public var category: DataSchema.PlaceCategory?
    /// Centroid as [longitude, latitude].
    public var point: [Double]?
    /// Optional extent as [minLongitude, minLatitude, maxLongitude, maxLatitude].
    /// Null when no bounds are known.
    public var bounds: [Double]?
    /// ISO 3166-1 alpha-2 country code. Example: "FR".
    /// Null when the upstream geocoder did not resolve administrative context for this result.
    public var country: String?
    /// Localized country display name. Null when the upstream geocoder did not resolve
    /// administrative context for this result.
    public var countryName: String?
    /// Administrative region or state. Null when the upstream geocoder did not resolve
    /// administrative context for this result.
    public var region: String?
    /// Administrative county or department. Null when the upstream geocoder did not resolve
    /// administrative context for this result.
    public var county: String?
    /// City name. Null when the upstream geocoder did not resolve administrative context for this
    /// result.
    public var city: String?
    /// Postal code. Null when the result is coarser than a postcode, or the
    /// upstream geocoder did not resolve one.
    public var postcode: String?
    /// Street name. Null unless the result resolved to a street or an address
    /// on one.
    public var street: String?
    /// Building number on the street. Null unless the result resolved to a
    /// specific address.
    public var houseNumber: String?

    /// Creates a `Place` from the properties the contract requires, the optional ones being set in
    /// `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.osm = nil
      self.name = nil
      self.label = nil
      self.layer = nil
      self.category = nil
      self.point = nil
      self.bounds = nil
      self.country = nil
      self.countryName = nil
      self.region = nil
      self.county = nil
      self.city = nil
      self.postcode = nil
      self.street = nil
      self.houseNumber = nil
      configure(&self)
    }

    /// Reads a `Place` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.osm = try container.decodeIfPresent(DataSchema.OSMRef.self, forKey: "osm")
      self.name = try container.decodeIfPresent(String.self, forKey: "name")
      self.label = try container.decodeIfPresent(String.self, forKey: "label")
      self.layer = try container.decodeIfPresent(DataSchema.GeocodeLayer.self, forKey: "layer")
      self.category = try container.decodeIfPresent(
        DataSchema.PlaceCategory.self, forKey: "category")
      self.point = try container.decodeIfPresent([Double].self, forKey: "point")
      self.bounds = try container.decodeIfPresent([Double].self, forKey: "bounds")
      self.country = try container.decodeIfPresent(String.self, forKey: "country")
      self.countryName = try container.decodeIfPresent(String.self, forKey: "countryName")
      self.region = try container.decodeIfPresent(String.self, forKey: "region")
      self.county = try container.decodeIfPresent(String.self, forKey: "county")
      self.city = try container.decodeIfPresent(String.self, forKey: "city")
      self.postcode = try container.decodeIfPresent(String.self, forKey: "postcode")
      self.street = try container.decodeIfPresent(String.self, forKey: "street")
      self.houseNumber = try container.decodeIfPresent(String.self, forKey: "houseNumber")
    }

    /// Writes a `Place` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.osm, forKey: "osm")
      try container.encodeIfPresent(self.name, forKey: "name")
      try container.encodeIfPresent(self.label, forKey: "label")
      try container.encodeIfPresent(self.layer, forKey: "layer")
      try container.encodeIfPresent(self.category, forKey: "category")
      try container.encodeIfPresent(self.point, forKey: "point")
      try container.encodeIfPresent(self.bounds, forKey: "bounds")
      try container.encodeIfPresent(self.country, forKey: "country")
      try container.encodeIfPresent(self.countryName, forKey: "countryName")
      try container.encodeIfPresent(self.region, forKey: "region")
      try container.encodeIfPresent(self.county, forKey: "county")
      try container.encodeIfPresent(self.city, forKey: "city")
      try container.encodeIfPresent(self.postcode, forKey: "postcode")
      try container.encodeIfPresent(self.street, forKey: "street")
      try container.encodeIfPresent(self.houseNumber, forKey: "houseNumber")
    }
  }
}
