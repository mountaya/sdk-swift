// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// A single OpenStreetMap tag attached to a feature.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct OSMTag: Sendable, Hashable, Codable {
    /// OSM tag key. Example: "ele" or "name:fr".
    public var key: String?
    /// OSM tag value. Example: "4810" or "Mont Blanc".
    public var value: String?

    /// Creates a `OSMTag` from the properties the contract requires, the optional ones being set in
    /// `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.key = nil
      self.value = nil
      configure(&self)
    }

    /// Reads a `OSMTag` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.key = try container.decodeIfPresent(String.self, forKey: "key")
      self.value = try container.decodeIfPresent(String.self, forKey: "value")
    }

    /// Writes a `OSMTag` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.key, forKey: "key")
      try container.encodeIfPresent(self.value, forKey: "value")
    }
  }
}
