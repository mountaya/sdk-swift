// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// The `extensions.metadata` object every listing that pages returns. It
  /// carries the page and nothing else, so `extensions.metadata.pagination` is the
  /// one path a client reads paging from. A listing that does not page, a
  /// catalog or a usage series, answers with no `extensions` at all.
  public struct ListMetadata: Sendable, Hashable, Codable {
    /// The page this listing served, and the cursor of the next one.
    public var pagination: RestSchema.PaginationMetadata

    /// Creates a `ListMetadata` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      pagination: RestSchema.PaginationMetadata,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.pagination = pagination
      configure(&self)
    }

    /// Reads a `ListMetadata` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.pagination = try container.decode(
        RestSchema.PaginationMetadata.self, forKey: "pagination")
    }

    /// Writes a `ListMetadata` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.pagination, forKey: "pagination")
    }
  }
}
