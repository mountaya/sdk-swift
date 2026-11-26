// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// A coordinate index range with the access restrictions tagged on the ways it
  /// follows.
  public struct RoadAccessInfo: Sendable, Hashable, Codable {
    /// Start index in the route coordinates array (inclusive).
    public var from_index: Int
    /// End index in the route coordinates array (inclusive).
    public var to_index: Int
    /// Every access restriction tagged on this stretch, for the activity's mode
    /// of travel. A way can carry several at once. Never empty: a stretch with no
    /// restriction is not listed at all.
    public var values: [RestSchema.RoadAccessRestrictionType]

    /// Creates a `RoadAccessInfo` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      from_index: Int,
      to_index: Int,
      values: [RestSchema.RoadAccessRestrictionType],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.from_index = from_index
      self.to_index = to_index
      self.values = values
      configure(&self)
    }

    /// Reads a `RoadAccessInfo` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.from_index = try container.decode(Int.self, forKey: "from_index")
      self.to_index = try container.decode(Int.self, forKey: "to_index")
      self.values = try container.decode(
        [RestSchema.RoadAccessRestrictionType].self, forKey: "values")
    }

    /// Writes a `RoadAccessInfo` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.from_index, forKey: "from_index")
      try container.encode(self.to_index, forKey: "to_index")
      try container.encode(self.values, forKey: "values")
    }
  }
}
