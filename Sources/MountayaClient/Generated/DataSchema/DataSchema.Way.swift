// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// A single named way result.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct Way: Sendable, Hashable, Codable {
    /// Reference to the underlying OpenStreetMap feature.
    public var osm: DataSchema.OSMRef?
    /// Localized display name.
    public var name: String?
    /// OSM highway tag value (e.g. path, track, footway).
    public var highway: String?
    /// OSM surface tag value. Often null: present only where the way's data carries that tag.
    public var surface: String?
    /// OSM sac_scale tag value. Often null: present only where the way's data carries that tag.
    public var sacScale: String?
    /// Representative coordinate as [longitude, latitude].
    public var point: [Double]?
    /// Bounding box as [minLongitude, minLatitude, maxLongitude, maxLatitude].
    /// Null when the upstream geocoder returned no extent.
    public var bounds: [Double]?
    /// Polyline coordinates as a list of [longitude, latitude] pairs; null when
    /// the upstream geocoder did not provide a polyline.
    public var coordinates: [[Double]]?
    /// Activities whose routing profile accepts this way.
    ///
    /// Reports what was actually established, not the full catalog. Filtering the
    /// search to one activity narrows this to that activity alone: the other
    /// compatible ones are neither checked nor claimed, because a filtered search
    /// verifies only what it was asked about. Read an absent activity as unreported
    /// rather than as refused.
    public var activityCompatible: [DataSchema.ActivitySlug]?
    /// ISO 3166-1 alpha-2 country code, e.g. "FR" or "BE". Null when the
    /// upstream geocoder did not resolve admin context.
    public var country: String?
    /// Localized display name of the way's country. Null when not available.
    public var countryName: String?
    /// Administrative region or state the way belongs to (e.g. Haute-Savoie). Null when not
    /// available.
    public var region: String?
    /// City the way belongs to. Null when not available.
    public var city: String?

    /// Creates a `Way` from the properties the contract requires, the optional ones being set in
    /// `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.osm = nil
      self.name = nil
      self.highway = nil
      self.surface = nil
      self.sacScale = nil
      self.point = nil
      self.bounds = nil
      self.coordinates = nil
      self.activityCompatible = nil
      self.country = nil
      self.countryName = nil
      self.region = nil
      self.city = nil
      configure(&self)
    }

    /// Reads a `Way` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.osm = try container.decodeIfPresent(DataSchema.OSMRef.self, forKey: "osm")
      self.name = try container.decodeIfPresent(String.self, forKey: "name")
      self.highway = try container.decodeIfPresent(String.self, forKey: "highway")
      self.surface = try container.decodeIfPresent(String.self, forKey: "surface")
      self.sacScale = try container.decodeIfPresent(String.self, forKey: "sacScale")
      self.point = try container.decodeIfPresent([Double].self, forKey: "point")
      self.bounds = try container.decodeIfPresent([Double].self, forKey: "bounds")
      self.coordinates = try container.decodeIfPresent([[Double]].self, forKey: "coordinates")
      self.activityCompatible = try container.decodeIfPresent(
        [DataSchema.ActivitySlug].self, forKey: "activityCompatible")
      self.country = try container.decodeIfPresent(String.self, forKey: "country")
      self.countryName = try container.decodeIfPresent(String.self, forKey: "countryName")
      self.region = try container.decodeIfPresent(String.self, forKey: "region")
      self.city = try container.decodeIfPresent(String.self, forKey: "city")
    }

    /// Writes a `Way` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.osm, forKey: "osm")
      try container.encodeIfPresent(self.name, forKey: "name")
      try container.encodeIfPresent(self.highway, forKey: "highway")
      try container.encodeIfPresent(self.surface, forKey: "surface")
      try container.encodeIfPresent(self.sacScale, forKey: "sacScale")
      try container.encodeIfPresent(self.point, forKey: "point")
      try container.encodeIfPresent(self.bounds, forKey: "bounds")
      try container.encodeIfPresent(self.coordinates, forKey: "coordinates")
      try container.encodeIfPresent(self.activityCompatible, forKey: "activityCompatible")
      try container.encodeIfPresent(self.country, forKey: "country")
      try container.encodeIfPresent(self.countryName, forKey: "countryName")
      try container.encodeIfPresent(self.region, forKey: "region")
      try container.encodeIfPresent(self.city, forKey: "city")
    }
  }
}
