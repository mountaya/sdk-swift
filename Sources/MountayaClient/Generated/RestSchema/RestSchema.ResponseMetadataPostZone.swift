// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Response metadata returned when creating a zone collides with an existing
  /// one, by name or by id. Carries the identifier of the zone it collided with.
  public struct ResponseMetadataPostZone: Sendable, Hashable, Codable {
    /// The zone the new one collided with, so a client can read it back and
    /// decide what to send instead rather than guess which one it was. Present on
    /// a 409 and on nothing else.
    public var zone: RestSchema.ConflictMetadata

    /// Creates a `ResponseMetadataPostZone` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      zone: RestSchema.ConflictMetadata,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.zone = zone
      configure(&self)
    }

    /// Reads a `ResponseMetadataPostZone` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.zone = try container.decode(RestSchema.ConflictMetadata.self, forKey: "zone")
    }

    /// Writes a `ResponseMetadataPostZone` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.zone, forKey: "zone")
    }
  }
}
