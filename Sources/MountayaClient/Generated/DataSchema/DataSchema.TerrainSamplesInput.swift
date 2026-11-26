// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Input for a point terrain query.
  public struct TerrainSamplesInput: Sendable, Hashable, Codable {
    /// Locations as [longitude, latitude] coordinate pairs (WGS 84).
    /// Example: [[6.8712, 45.9231], [6.7991, 45.8915]] (Chamonix, Les Houches).
    /// Must contain between 1 and 100 locations; any other count is
    /// VALIDATION_FAILED at ["input", "locations"]. Each is exactly two numbers, a
    /// longitude between -180 and 180 and a latitude between -90 and 90, and one that
    /// is not is VALIDATION_FAILED at ["input", "locations", i]. The locations fall in
    /// at most 256 distinct elevation tiles at zoom 14, counted before any is
    /// fetched, and more is VALIDATION_FAILED at ["input", "locations"]; the 100
    /// locations a query may carry reach at most 100.
    public var locations: [[Double]]

    /// Creates a `TerrainSamplesInput` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      locations: [[Double]],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.locations = locations
      configure(&self)
    }

    /// Reads a `TerrainSamplesInput` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.locations = try container.decode([[Double]].self, forKey: "locations")
    }

    /// Writes a `TerrainSamplesInput` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.locations, forKey: "locations")
    }
  }
}
