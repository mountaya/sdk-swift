// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Stream frame announcing that the soft edit lock on an entity was given up, so
  /// the other members can clear its badge and edit it themselves. It follows
  /// either a lock release signal from the holder or a connection of the holder's
  /// closing, one frame per lock released. A closing connection releases the
  /// locks held through it even while the member has another connection open,
  /// and the member's last connection releases every lock they still held.
  ///
  /// Releasing a lock nobody holds changes nothing and produces no frame, and so
  /// does a lock that lapses on its own: the next lock snapshot stops listing it.
  public struct CollabLockReleasedEvent: Sendable, Hashable, Codable {
    /// Always `lock.released` on this event, and the value of the record's
    /// `event:` field. Branch on it to route the event; the enum carries every
    /// type a collaboration stream can send.
    ///
    /// It is always `lock.released`, the discriminator value naming this member of its union.
    public var type: RestSchema.CollabStreamEventType {
      "lock.released"
    }
    /// Which entity the lock was released on, by kind and identifier.
    public var entity: RestSchema.CollabEntity
    /// Identifier of the member who released the lock.
    public var user_id: String

    /// Creates a `CollabLockReleasedEvent` from the properties the contract requires, the optional
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

    /// Reads a `CollabLockReleasedEvent` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.entity = try container.decode(RestSchema.CollabEntity.self, forKey: "entity")
      self.user_id = try container.decode(String.self, forKey: "user_id")
    }

    /// Writes a `CollabLockReleasedEvent` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
      try container.encode(self.entity, forKey: "entity")
      try container.encode(self.user_id, forKey: "user_id")
    }
  }
}
