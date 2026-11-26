// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Where a page sits, and the cursor of the next.
  public struct PageMeta: Sendable, Hashable, Codable {
    /// The contract's `total`.
    public var total: Int
    /// The contract's `next_cursor`.
    public var next_cursor: String?

    /// Creates a `PageMeta` from the properties the contract requires, the optional ones being set
    /// in `configure`.
    public init(
      total: Int,
      next_cursor: String?,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.total = total
      self.next_cursor = next_cursor
      configure(&self)
    }

    /// Reads a `PageMeta` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.total = try container.decode(Int.self, forKey: "total")
      self.next_cursor = try container.decodeIfPresent(String.self, forKey: "next_cursor")
    }

    /// Writes a `PageMeta` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.total, forKey: "total")
      try container.encodeNullable(self.next_cursor, forKey: "next_cursor")
    }
  }
}
