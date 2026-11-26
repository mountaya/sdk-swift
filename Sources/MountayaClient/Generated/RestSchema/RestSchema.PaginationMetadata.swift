// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// The page a listing served, reported at `extensions.metadata.pagination` on
  /// every listing that pages. A listing pages by cursor: the next page is asked
  /// for with `next_cursor`, and the last page reports none.
  public struct PaginationMetadata: Sendable, Hashable, Codable {
    /// The page size the listing was served at: the `limit` sent, or 50 when
    /// none was.
    public var limit: Int
    /// The `cursor` that asks for the page after this one, with the same
    /// filters and `sort`, or null when this page is the last. A page that is
    /// not the last may hold fewer than `limit` items; the end is told by this
    /// field alone.
    public var next_cursor: String?

    /// Creates a `PaginationMetadata` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      limit: Int,
      next_cursor: String?,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.limit = limit
      self.next_cursor = next_cursor
      configure(&self)
    }

    /// Reads a `PaginationMetadata` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.limit = try container.decode(Int.self, forKey: "limit")
      self.next_cursor = try container.decodeIfPresent(String.self, forKey: "next_cursor")
    }

    /// Writes a `PaginationMetadata` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.limit, forKey: "limit")
      try container.encodeNullable(self.next_cursor, forKey: "next_cursor")
    }
  }
}
