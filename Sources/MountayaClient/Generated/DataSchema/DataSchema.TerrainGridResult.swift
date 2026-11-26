// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Result of a gridded terrain query over an area.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct TerrainGridResult: Sendable, Hashable, Codable {
    /// Total number of cells returned (cols * rows).
    public var count: Int?
    /// Number of cells that fall inside DEM coverage. Weight any average by this
    /// rather than by count.
    public var coveredCount: Int?
    /// Zoom level of the sampled DEM tiles, so a result can be reproduced exactly.
    /// A standard Web Mercator XYZ zoom, chosen by the server rather than the
    /// caller: every request samples at the same zoom, the deepest the elevation
    /// source serves, so two answers about the same ground are always comparable.
    /// Treat it as reported, not requested.
    public var zoom: Int?
    /// Ground resolution of one DEM pixel in meters, measured at the first sample's
    /// latitude. It varies with latitude, so over a result spanning a wide range of
    /// latitudes it describes the first sample's ground rather than every sample's.
    public var resolutionMeters: Double?
    /// Number of grid columns.
    public var cols: Int?
    /// Number of grid rows.
    public var rows: Int?
    /// Grid cells in row-major order: the cell at (col, row) is at index row * cols + col.
    /// Row 0 runs along the northern edge of the box and column 0 along its western
    /// edge, and each cell is read at its centre rather than at a corner.
    public var cells: [DataSchema.TerrainSample]?

    /// Creates a `TerrainGridResult` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.count = nil
      self.coveredCount = nil
      self.zoom = nil
      self.resolutionMeters = nil
      self.cols = nil
      self.rows = nil
      self.cells = nil
      configure(&self)
    }

    /// Reads a `TerrainGridResult` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.count = try container.decodeIfPresent(Int.self, forKey: "count")
      self.coveredCount = try container.decodeIfPresent(Int.self, forKey: "coveredCount")
      self.zoom = try container.decodeIfPresent(Int.self, forKey: "zoom")
      self.resolutionMeters = try container.decodeIfPresent(Double.self, forKey: "resolutionMeters")
      self.cols = try container.decodeIfPresent(Int.self, forKey: "cols")
      self.rows = try container.decodeIfPresent(Int.self, forKey: "rows")
      self.cells = try container.decodeIfPresent([DataSchema.TerrainSample].self, forKey: "cells")
    }

    /// Writes a `TerrainGridResult` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.count, forKey: "count")
      try container.encodeIfPresent(self.coveredCount, forKey: "coveredCount")
      try container.encodeIfPresent(self.zoom, forKey: "zoom")
      try container.encodeIfPresent(self.resolutionMeters, forKey: "resolutionMeters")
      try container.encodeIfPresent(self.cols, forKey: "cols")
      try container.encodeIfPresent(self.rows, forKey: "rows")
      try container.encodeIfPresent(self.cells, forKey: "cells")
    }
  }
}
