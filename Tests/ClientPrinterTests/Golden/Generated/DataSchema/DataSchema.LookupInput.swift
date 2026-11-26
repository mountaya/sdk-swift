// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// The contract's `LookupInput`.
  public struct LookupInput: Sendable, Hashable, Codable {
    /// The contract's `query`.
    public var query: String
    /// The contract's `limit`.
    public var limit: Int?
    /// The contract's `kinds`.
    public var kinds: [DataSchema.LookupKind]?

    /// Creates a `LookupInput` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      query: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.query = query
      self.limit = nil
      self.kinds = nil
      configure(&self)
    }

    /// Reads a `LookupInput` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.query = try container.decode(String.self, forKey: "query")
      self.limit = try container.decodeIfPresent(Int.self, forKey: "limit")
      self.kinds = try container.decodeIfPresent([DataSchema.LookupKind].self, forKey: "kinds")
    }

    /// Writes a `LookupInput` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.query, forKey: "query")
      try container.encodeIfPresent(self.limit, forKey: "limit")
      try container.encodeIfPresent(self.kinds, forKey: "kinds")
    }
  }
}
