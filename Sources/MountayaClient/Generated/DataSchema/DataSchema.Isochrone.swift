// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// A single isochrone polygon with its associated range value and metadata.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct Isochrone: Sendable, Hashable, Codable {
    /// The requested range value this polygon was computed for, in seconds or meters
    /// as the input range type says.
    public var value: Double?
    /// Area of the isochrone polygon in square meters. Null when the routing
    /// provider did not report it for this polygon.
    public var area: Double?
    /// How much of the theoretically reachable ground the isochrone actually
    /// covers, from 0 to 1. The theoretical area is the circle the same travel
    /// budget would cover with no network and no terrain in the way, so a value
    /// near 1 means the network radiates freely from the origin and a low value
    /// means it is constrained: a valley floor, a coastline, a single road out.
    /// Null when the routing provider did not report it for this polygon.
    public var reachFactor: Double?
    /// Center point of the isochrone as [longitude, latitude] (WGS 84). Null when the
    /// routing provider reports no center for this isochrone: the value is forwarded
    /// verbatim from the provider's response and is not reconstructed from the input
    /// location, so its absence is reported as null rather than as an empty array.
    public var center: [Double]?
    /// Polygon geometry of the isochrone.
    public var geometry: GeoJSONGeometry?

    /// Creates a `Isochrone` from the properties the contract requires, the optional ones being set
    /// in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.value = nil
      self.area = nil
      self.reachFactor = nil
      self.center = nil
      self.geometry = nil
      configure(&self)
    }

    /// Reads a `Isochrone` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.value = try container.decodeIfPresent(Double.self, forKey: "value")
      self.area = try container.decodeIfPresent(Double.self, forKey: "area")
      self.reachFactor = try container.decodeIfPresent(Double.self, forKey: "reachFactor")
      self.center = try container.decodeIfPresent([Double].self, forKey: "center")
      self.geometry = try container.decodeIfPresent(GeoJSONGeometry.self, forKey: "geometry")
    }

    /// Writes a `Isochrone` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.value, forKey: "value")
      try container.encodeIfPresent(self.area, forKey: "area")
      try container.encodeIfPresent(self.reachFactor, forKey: "reachFactor")
      try container.encodeIfPresent(self.center, forKey: "center")
      try container.encodeIfPresent(self.geometry, forKey: "geometry")
    }
  }
}
