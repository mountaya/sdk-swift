// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Elevation summary for a computed route, including altitude bounds, total
  /// elevation gain/loss, and gradient extremes.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct ElevationSummary: Sendable, Hashable, Codable {
    /// Altitude range along the route in meters above sea level.
    public var altitude: DataSchema.MetricRange?
    /// Total elevation gain (ascent) in meters.
    public var ascent: Double?
    /// Total elevation loss (descent) in meters.
    public var descent: Double?
    /// Gradient range along the route in degrees. Positive values indicate uphill,
    /// negative values indicate downhill.
    public var gradient: DataSchema.MetricRange?

    /// Creates a `ElevationSummary` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.altitude = nil
      self.ascent = nil
      self.descent = nil
      self.gradient = nil
      configure(&self)
    }

    /// Reads a `ElevationSummary` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.altitude = try container.decodeIfPresent(DataSchema.MetricRange.self, forKey: "altitude")
      self.ascent = try container.decodeIfPresent(Double.self, forKey: "ascent")
      self.descent = try container.decodeIfPresent(Double.self, forKey: "descent")
      self.gradient = try container.decodeIfPresent(DataSchema.MetricRange.self, forKey: "gradient")
    }

    /// Writes a `ElevationSummary` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.altitude, forKey: "altitude")
      try container.encodeIfPresent(self.ascent, forKey: "ascent")
      try container.encodeIfPresent(self.descent, forKey: "descent")
      try container.encodeIfPresent(self.gradient, forKey: "gradient")
    }
  }
}
