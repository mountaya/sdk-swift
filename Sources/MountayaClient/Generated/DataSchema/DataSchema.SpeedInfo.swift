// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// A coordinate index range with an associated travel speed in km/h.
  ///
  /// This is the RESOLVED speed the travel-time model computed for that stretch from
  /// the flat pace and the ground it crosses, not the flat pace itself.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct SpeedInfo: Sendable, Hashable, Codable {
    /// Start index in the coordinates array (inclusive).
    public var fromIndex: Int?
    /// End index in the coordinates array (inclusive).
    public var toIndex: Int?
    /// Travel speed in km/h over this stretch. Always positive. Slower than the flat
    /// pace on a climb, faster on a descent, and reduced further by a coarse surface
    /// or a technical trail. Never above the activity's maximum speed, in km/h: 12 for
    /// HIKING_AND_TRAIL, 20 for PROFESSIONAL_TRAIL, 22 for RUNNING, 60 for
    /// ROAD_CYCLING, 40 for BACKCOUNTRY_SKIING and SKI_TOURING, 30 for
    /// CROSS_COUNTRY_SKIING and 8 for SNOWSHOE_WALKING. A stretch at that cap stays
    /// there whatever `speed` asks for.
    public var value: Double?

    /// Creates a `SpeedInfo` from the properties the contract requires, the optional ones being set
    /// in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.fromIndex = nil
      self.toIndex = nil
      self.value = nil
      configure(&self)
    }

    /// Reads a `SpeedInfo` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.fromIndex = try container.decodeIfPresent(Int.self, forKey: "fromIndex")
      self.toIndex = try container.decodeIfPresent(Int.self, forKey: "toIndex")
      self.value = try container.decodeIfPresent(Double.self, forKey: "value")
    }

    /// Writes a `SpeedInfo` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.fromIndex, forKey: "fromIndex")
      try container.encodeIfPresent(self.toIndex, forKey: "toIndex")
      try container.encodeIfPresent(self.value, forKey: "value")
    }
  }
}
