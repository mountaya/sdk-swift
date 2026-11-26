// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// What a lookup found.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct LookupResult: Sendable, Hashable, Codable {
    /// The contract's `items`.
    public var items: [DataSchema.LookupItem]?
    /// The contract's `total`.
    public var total: Int?
    /// The contract's `grid`.
    public var grid: [[Double?]]?

    /// Creates a `LookupResult` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.items = nil
      self.total = nil
      self.grid = nil
      configure(&self)
    }

    /// Reads a `LookupResult` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.items = try container.decodeIfPresent([DataSchema.LookupItem].self, forKey: "items")
      self.total = try container.decodeIfPresent(Int.self, forKey: "total")
      self.grid = try container.decodeIfPresent([[Double?]].self, forKey: "grid")
    }

    /// Writes a `LookupResult` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.items, forKey: "items")
      try container.encodeIfPresent(self.total, forKey: "total")
      try container.encodeIfPresent(self.grid, forKey: "grid")
    }
  }
}
