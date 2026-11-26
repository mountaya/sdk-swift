// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// A coordinate index range with the access restrictions that apply to it.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct RoadAccessRestrictionInfo: Sendable, Hashable, Codable {
    /// Start index in the coordinates array (inclusive).
    public var fromIndex: Int?
    /// End index in the coordinates array (inclusive).
    public var toIndex: Int?
    /// Every access restriction tagged on this coordinate range, for the activity's
    /// mode of travel. A way can carry several at once. Never empty: a range with no
    /// restriction is not reported at all.
    public var values: [DataSchema.RoadAccessRestrictionType]?

    /// Creates a `RoadAccessRestrictionInfo` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.fromIndex = nil
      self.toIndex = nil
      self.values = nil
      configure(&self)
    }

    /// Reads a `RoadAccessRestrictionInfo` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.fromIndex = try container.decodeIfPresent(Int.self, forKey: "fromIndex")
      self.toIndex = try container.decodeIfPresent(Int.self, forKey: "toIndex")
      self.values = try container.decodeIfPresent(
        [DataSchema.RoadAccessRestrictionType].self, forKey: "values")
    }

    /// Writes a `RoadAccessRestrictionInfo` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.fromIndex, forKey: "fromIndex")
      try container.encodeIfPresent(self.toIndex, forKey: "toIndex")
      try container.encodeIfPresent(self.values, forKey: "values")
    }
  }
}
