// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// A single point-of-interest result.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct POI: Sendable, Hashable, Codable {
    /// Reference to the underlying OpenStreetMap feature.
    public var osm: DataSchema.OSMRef?
    /// Localized display name.
    public var name: String?
    /// Canonical POI category mapped from the underlying OSM tags.
    public var category: DataSchema.POICategory?
    /// Centroid as [longitude, latitude].
    public var point: [Double]?
    /// Elevation in meters above sea level, read from the OSM "ele" tag. Often null:
    /// present only where the place data carries that tag.
    public var elevation: Double?
    /// Selected OSM tags useful for UI rendering, present only where the place data
    /// carries them. Not exhaustive, and often empty.
    public var tags: [DataSchema.OSMTag]?
    /// Distance in meters from the buffered geometry itself, measured to its nearest
    /// edge rather than its nearest vertex, and 0 for a POI inside a Polygon (outside
    /// its holes). Only set when the query used a buffered area.
    public var distanceMeters: Double?
    /// ISO 3166-1 alpha-2 country code, e.g. "FR" or "BE". Null when the
    /// upstream geocoder did not resolve admin context.
    public var country: String?
    /// Localized display name of the POI's country. Null when not available.
    public var countryName: String?
    /// Administrative region or state the POI belongs to (e.g. Haute-Savoie). Null when not
    /// available.
    public var region: String?
    /// City the POI belongs to. Null when not available.
    public var city: String?

    /// Creates a `POI` from the properties the contract requires, the optional ones being set in
    /// `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.osm = nil
      self.name = nil
      self.category = nil
      self.point = nil
      self.elevation = nil
      self.tags = nil
      self.distanceMeters = nil
      self.country = nil
      self.countryName = nil
      self.region = nil
      self.city = nil
      configure(&self)
    }

    /// Reads a `POI` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.osm = try container.decodeIfPresent(DataSchema.OSMRef.self, forKey: "osm")
      self.name = try container.decodeIfPresent(String.self, forKey: "name")
      self.category = try container.decodeIfPresent(DataSchema.POICategory.self, forKey: "category")
      self.point = try container.decodeIfPresent([Double].self, forKey: "point")
      self.elevation = try container.decodeIfPresent(Double.self, forKey: "elevation")
      self.tags = try container.decodeIfPresent([DataSchema.OSMTag].self, forKey: "tags")
      self.distanceMeters = try container.decodeIfPresent(Double.self, forKey: "distanceMeters")
      self.country = try container.decodeIfPresent(String.self, forKey: "country")
      self.countryName = try container.decodeIfPresent(String.self, forKey: "countryName")
      self.region = try container.decodeIfPresent(String.self, forKey: "region")
      self.city = try container.decodeIfPresent(String.self, forKey: "city")
    }

    /// Writes a `POI` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.osm, forKey: "osm")
      try container.encodeIfPresent(self.name, forKey: "name")
      try container.encodeIfPresent(self.category, forKey: "category")
      try container.encodeIfPresent(self.point, forKey: "point")
      try container.encodeIfPresent(self.elevation, forKey: "elevation")
      try container.encodeIfPresent(self.tags, forKey: "tags")
      try container.encodeIfPresent(self.distanceMeters, forKey: "distanceMeters")
      try container.encodeIfPresent(self.country, forKey: "country")
      try container.encodeIfPresent(self.countryName, forKey: "countryName")
      try container.encodeIfPresent(self.region, forKey: "region")
      try container.encodeIfPresent(self.city, forKey: "city")
    }
  }
}
