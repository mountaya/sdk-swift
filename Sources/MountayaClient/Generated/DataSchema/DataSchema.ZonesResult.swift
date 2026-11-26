// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Result of the zones target.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct ZonesResult: Sendable, Hashable, Codable {
    /// Number of zones returned: the length of `zones`, at most `limit`.
    public var count: Int?
    /// List of zone references ordered by relevance.
    public var zones: [DataSchema.ZoneSearchResult]?

    /// Creates a `ZonesResult` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.count = nil
      self.zones = nil
      configure(&self)
    }

    /// Reads a `ZonesResult` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.count = try container.decodeIfPresent(Int.self, forKey: "count")
      self.zones = try container.decodeIfPresent(
        [DataSchema.ZoneSearchResult].self, forKey: "zones")
    }

    /// Writes a `ZonesResult` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.count, forKey: "count")
      try container.encodeIfPresent(self.zones, forKey: "zones")
    }
  }
}
