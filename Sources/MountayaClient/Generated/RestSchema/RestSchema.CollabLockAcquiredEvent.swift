// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Stream frame announcing that a member took the soft edit lock on an entity, so
  /// the other members can badge it as being edited and hold back their own writes.
  /// It follows a lock acquire signal the holder sent and that the server granted;
  /// a refused request produces no frame.
  ///
  /// It is a delta between snapshots and can only ever add to a lock set; the
  /// authoritative set is the lock snapshot.
  public struct CollabLockAcquiredEvent: Sendable, Hashable, Codable {
    /// Always `lock.acquired` on this event, and the value of the record's
    /// `event:` field. Branch on it to route the event; the enum carries every
    /// type a collaboration stream can send.
    ///
    /// It is always `lock.acquired`, the discriminator value naming this member of its union.
    public var type: RestSchema.CollabStreamEventType {
      "lock.acquired"
    }
    /// Which entity the lock was taken on, by kind and identifier.
    public var entity: RestSchema.CollabEntity
    /// Identifier of the member who holds the lock.
    public var user_id: String

    /// Creates a `CollabLockAcquiredEvent` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      entity: RestSchema.CollabEntity,
      user_id: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.entity = entity
      self.user_id = user_id
      configure(&self)
    }

    /// Reads a `CollabLockAcquiredEvent` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.entity = try container.decode(RestSchema.CollabEntity.self, forKey: "entity")
      self.user_id = try container.decode(String.self, forKey: "user_id")
    }

    /// Writes a `CollabLockAcquiredEvent` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
      try container.encode(self.entity, forKey: "entity")
      try container.encode(self.user_id, forKey: "user_id")
    }
  }
}
