// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Buffered-area input combining a GeoJSON geometry with a radial buffer
  /// distance in meters. The buffer expands the geometry into a search area for
  /// the POI query.
  public struct BufferedAreaInput: Sendable, Hashable, Codable {
    /// GeoJSON LineString or Polygon used as the spine of the buffered area. It
    /// carries 2 to 10,000 positions, a Polygon's holes counting toward that total,
    /// and the line, or a Polygon's outer ring, is at most 500 km long. Any other
    /// type, or a geometry outside those bounds, is VALIDATION_FAILED at or below
    /// ["input", "buffered", "geometry"].
    public var geometry: GeoJSONGeometry
    /// Radial buffer distance in meters used to expand the geometry. Must be
    /// between 1 and 5000 (VALIDATION_FAILED at ["input", "buffered", "bufferMeters"]
    /// otherwise).
    public var bufferMeters: Double

    /// Creates a `BufferedAreaInput` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      geometry: GeoJSONGeometry,
      bufferMeters: Double,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.geometry = geometry
      self.bufferMeters = bufferMeters
      configure(&self)
    }

    /// Reads a `BufferedAreaInput` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.geometry = try container.decode(GeoJSONGeometry.self, forKey: "geometry")
      self.bufferMeters = try container.decode(Double.self, forKey: "bufferMeters")
    }

    /// Writes a `BufferedAreaInput` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.geometry, forKey: "geometry")
      try container.encode(self.bufferMeters, forKey: "bufferMeters")
    }
  }
}
