// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// A zone's area, as a GeoJSON Feature (RFC 7946) whose geometry is a single
  /// Polygon. Every zone mode stores one: a circle, a sector or a sensor footprint
  /// is the polygon that traces it. A feature carrying any other geometry, a `null`
  /// geometry included, is refused with a `400` naming `geojson.geometry`.
  public struct ZoneFeature: Sendable, Hashable, Codable {
    /// Discriminator for the GeoJSON object type. Always `Feature`.
    ///
    /// It is always "Feature", which this type writes itself.
    public var type: String {
      "Feature"
    }
    /// The zone's id. On a read it is always present and equals the zone's own
    /// `id`. On a create it is optional: a UUID sent here becomes the zone's id,
    /// and the server mints one when it is omitted. A UUID another zone already
    /// has is a `409`. On an update it is ignored.
    public var id: String?
    /// The zone's area. Positions are `[longitude, latitude]`; an optional third
    /// value is accepted and not kept, because a zone is a region on the ground.
    ///
    /// Latitude runs from -90 to 90. Longitude runs from -360 to 360, a turn
    /// wider than a point's, so that a ring crossing the antimeridian stays one
    /// ring: its longitudes are counted on past 180, or below -180, and no two
    /// neighbours stand on opposite edges of the map. `[179.5, -17]` followed by
    /// `[180.4, -17]` is nine tenths of a degree of ring. Written `[179.5, -17]`
    /// then `[-179.6, -17]`, the same two places are joined the other way round
    /// the world. The area is stored and returned with the longitudes it was
    /// written with.
    public var geometry: RestSchema.GeoJSONPolygon
    /// Free-form properties. They are accepted and not kept, since a zone's own
    /// fields carry what it says about itself, so a read returns an empty object.
    /// At most 64 fields and 16 KiB as sent.
    public var properties: [String: JSONValue]

    /// Creates a `ZoneFeature` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      geometry: RestSchema.GeoJSONPolygon,
      properties: [String: JSONValue],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.id = nil
      self.geometry = geometry
      self.properties = properties
      configure(&self)
    }

    /// Reads a `ZoneFeature` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decodeIfPresent(String.self, forKey: "id")
      self.geometry = try container.decode(RestSchema.GeoJSONPolygon.self, forKey: "geometry")
      self.properties = try container.decode([String: JSONValue].self, forKey: "properties")
    }

    /// Writes a `ZoneFeature` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
      try container.encodeIfPresent(self.id, forKey: "id")
      try container.encode(self.geometry, forKey: "geometry")
      try container.encode(self.properties, forKey: "properties")
    }
  }
}
