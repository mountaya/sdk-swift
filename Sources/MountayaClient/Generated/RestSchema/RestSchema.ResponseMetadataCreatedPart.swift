// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// What a write that created a part of an itinerary created, at
  /// `extensions.metadata` of its `201`. The answer's `data` is the whole
  /// itinerary, as every write to one answers it, so this is how a client finds
  /// the part it just made without searching for it; `Location` names the same
  /// part.
  public struct ResponseMetadataCreatedPart: Sendable, Hashable, Codable {
    /// The part created.
    public var created: RestSchema.ResponseMetadataCreatedPartCreated

    /// Creates a `ResponseMetadataCreatedPart` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      created: RestSchema.ResponseMetadataCreatedPartCreated,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.created = created
      configure(&self)
    }

    /// Reads a `ResponseMetadataCreatedPart` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.created = try container.decode(
        RestSchema.ResponseMetadataCreatedPartCreated.self, forKey: "created")
    }

    /// Writes a `ResponseMetadataCreatedPart` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.created, forKey: "created")
    }
  }
}
