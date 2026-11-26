// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// A minimum/maximum range. Units depend on the context in which it is used.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct MetricRange: Sendable, Hashable, Codable {
    /// Upper bound of the range.
    public var max: Double?
    /// Lower bound of the range.
    public var min: Double?

    /// Creates a `MetricRange` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.max = nil
      self.min = nil
      configure(&self)
    }

    /// Reads a `MetricRange` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.max = try container.decodeIfPresent(Double.self, forKey: "max")
      self.min = try container.decodeIfPresent(Double.self, forKey: "min")
    }

    /// Writes a `MetricRange` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.max, forKey: "max")
      try container.encodeIfPresent(self.min, forKey: "min")
    }
  }
}
