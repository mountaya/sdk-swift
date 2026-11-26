// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Input for a gridded terrain query over an area.
  public struct TerrainGridInput: Sendable, Hashable, Codable {
    /// [minLongitude, minLatitude, maxLongitude, maxLatitude] bounding box to sample:
    /// exactly four values, each minimum strictly below its maximum, both corners
    /// valid coordinates, and an area of at most 100 km². A box that breaks any of
    /// these is VALIDATION_FAILED at or below ["input", "bbox"]. The grid's cells
    /// also fall in at most 256 distinct elevation tiles at zoom 14, counted from
    /// the laid-out cells before any is fetched, and more is VALIDATION_FAILED at
    /// ["input", "bbox"]. A tile's ground shrinks toward the poles, so a full 64 by
    /// 64 grid over 100 km² fits up to about 70 degrees of latitude, and nearer the
    /// poles needs a smaller box or fewer cells.
    /// Example: [6.81, 45.90, 6.87, 45.94] (the Aiguille du Midi cirque).
    public var bbox: [Double]
    /// Number of grid columns. Must be between 2 and 64 (VALIDATION_FAILED at
    /// ["input", "cols"] otherwise).
    public var cols: Int?
    /// Number of grid rows. Must be between 2 and 64 (VALIDATION_FAILED at
    /// ["input", "rows"] otherwise).
    public var rows: Int?

    /// Creates a `TerrainGridInput` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      bbox: [Double],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.bbox = bbox
      self.cols = nil
      self.rows = nil
      configure(&self)
    }

    /// Reads a `TerrainGridInput` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.bbox = try container.decode([Double].self, forKey: "bbox")
      self.cols = try container.decodeIfPresent(Int.self, forKey: "cols")
      self.rows = try container.decodeIfPresent(Int.self, forKey: "rows")
    }

    /// Writes a `TerrainGridInput` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.bbox, forKey: "bbox")
      try container.encodeIfPresent(self.cols, forKey: "cols")
      try container.encodeIfPresent(self.rows, forKey: "rows")
    }
  }
}
