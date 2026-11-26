// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// A coordinate index range with an associated trail difficulty.
  public struct TrailDifficultyInfo: Sendable, Hashable, Codable {
    /// Start index in the route coordinates array (inclusive).
    public var from_index: Int
    /// End index in the route coordinates array (inclusive).
    public var to_index: Int
    /// The difficulty grade over this stretch of the geometry, on the scale the
    /// itinerary's activity is graded by.
    public var value: RestSchema.TrailDifficultyType

    /// Creates a `TrailDifficultyInfo` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      from_index: Int,
      to_index: Int,
      value: RestSchema.TrailDifficultyType,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.from_index = from_index
      self.to_index = to_index
      self.value = value
      configure(&self)
    }

    /// Reads a `TrailDifficultyInfo` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.from_index = try container.decode(Int.self, forKey: "from_index")
      self.to_index = try container.decode(Int.self, forKey: "to_index")
      self.value = try container.decode(RestSchema.TrailDifficultyType.self, forKey: "value")
    }

    /// Writes a `TrailDifficultyInfo` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.from_index, forKey: "from_index")
      try container.encode(self.to_index, forKey: "to_index")
      try container.encode(self.value, forKey: "value")
    }
  }
}
