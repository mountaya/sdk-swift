// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// One held soft edit lock: the locked entity and the member holding it. It is
  /// the entry shape inside a lock snapshot, so a client can badge the entities
  /// somebody else is already editing.
  public struct CollabLock: Sendable, Hashable, Codable {
    /// Which entity this lock is held on, by kind and identifier.
    public var entity: RestSchema.CollabEntity
    /// Identifier of the member holding the lock.
    public var user_id: String

    /// Creates a `CollabLock` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      entity: RestSchema.CollabEntity,
      user_id: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.entity = entity
      self.user_id = user_id
      configure(&self)
    }

    /// Reads a `CollabLock` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.entity = try container.decode(RestSchema.CollabEntity.self, forKey: "entity")
      self.user_id = try container.decode(String.self, forKey: "user_id")
    }

    /// Writes a `CollabLock` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.entity, forKey: "entity")
      try container.encode(self.user_id, forKey: "user_id")
    }
  }
}
