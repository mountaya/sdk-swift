// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Routing capabilities and parameters for an activity. Carries the feature flags
  /// indicating which capabilities are available, along with routing parameters
  /// such as the default travel speed.
  public struct ActivityCapabilities: Sendable, Hashable, Codable {
    /// Whether surface and way type analysis is available for this activity.
    public var analysis: Bool
    /// Default travel speed in km/h used to seed a segment's speed for this
    /// activity.
    public var default_speed: Double
    /// Whether turn-by-turn routing via the directions engine is available.
    public var directions: Bool
    /// Whether freehand line editing is available for this activity.
    public var linestring: Bool

    /// Creates a `ActivityCapabilities` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      analysis: Bool,
      default_speed: Double,
      directions: Bool,
      linestring: Bool,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.analysis = analysis
      self.default_speed = default_speed
      self.directions = directions
      self.linestring = linestring
      configure(&self)
    }

    /// Reads a `ActivityCapabilities` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.analysis = try container.decode(Bool.self, forKey: "analysis")
      self.default_speed = try container.decode(Double.self, forKey: "default_speed")
      self.directions = try container.decode(Bool.self, forKey: "directions")
      self.linestring = try container.decode(Bool.self, forKey: "linestring")
    }

    /// Writes a `ActivityCapabilities` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.analysis, forKey: "analysis")
      try container.encode(self.default_speed, forKey: "default_speed")
      try container.encode(self.directions, forKey: "directions")
      try container.encode(self.linestring, forKey: "linestring")
    }
  }
}
