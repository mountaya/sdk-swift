// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// A coordinate index range with an associated slope angle in degrees.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct SlopeInfo: Sendable, Hashable, Codable {
    /// Start index in the coordinates array (inclusive).
    public var fromIndex: Int?
    /// End index in the coordinates array (inclusive).
    public var toIndex: Int?
    /// Slope angle in degrees. Positive values indicate uphill, negative values indicate downhill.
    public var value: Double?

    /// Creates a `SlopeInfo` from the properties the contract requires, the optional ones being set
    /// in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.fromIndex = nil
      self.toIndex = nil
      self.value = nil
      configure(&self)
    }

    /// Reads a `SlopeInfo` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.fromIndex = try container.decodeIfPresent(Int.self, forKey: "fromIndex")
      self.toIndex = try container.decodeIfPresent(Int.self, forKey: "toIndex")
      self.value = try container.decodeIfPresent(Double.self, forKey: "value")
    }

    /// Writes a `SlopeInfo` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.fromIndex, forKey: "fromIndex")
      try container.encodeIfPresent(self.toIndex, forKey: "toIndex")
      try container.encodeIfPresent(self.value, forKey: "value")
    }
  }
}
