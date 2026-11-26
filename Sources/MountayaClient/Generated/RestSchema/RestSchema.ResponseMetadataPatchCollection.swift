// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Response metadata returned when updating a collection results in a name
  /// conflict. Carries the identifier of the existing collection that conflicts
  /// with the requested name.
  public struct ResponseMetadataPatchCollection: Sendable, Hashable, Codable {
    /// The collection that conflicted, so a client can read it back and reapply
    /// rather than guess which one moved. Present on a 409 and on nothing else.
    public var collection: RestSchema.ConflictMetadata

    /// Creates a `ResponseMetadataPatchCollection` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      collection: RestSchema.ConflictMetadata,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.collection = collection
      configure(&self)
    }

    /// Reads a `ResponseMetadataPatchCollection` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.collection = try container.decode(RestSchema.ConflictMetadata.self, forKey: "collection")
    }

    /// Writes a `ResponseMetadataPatchCollection` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.collection, forKey: "collection")
    }
  }
}
