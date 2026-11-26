// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Collaboration signal releasing the soft edit lock the caller holds on an
  /// entity. When the caller owns the lock the server broadcasts a lock.released
  /// event; releasing a lock the caller does not hold is a no-op.
  public struct CollabLockReleaseSignal: Sendable, Hashable, Codable {
    /// Always `lock.release` on this signal, and what the server routes it on.
    /// The enum carries every signal a client may send on a collaboration
    /// session.
    ///
    /// It is always `lock.release`, the discriminator value naming this member of its union.
    public var type: RestSchema.CollabSignalType {
      "lock.release"
    }
    /// Which entity to release the lock on, by kind and identifier. Releasing a
    /// lock the caller does not hold changes nothing.
    public var entity: RestSchema.CollabEntity

    /// Creates a `CollabLockReleaseSignal` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      entity: RestSchema.CollabEntity,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.entity = entity
      configure(&self)
    }

    /// Reads a `CollabLockReleaseSignal` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.entity = try container.decode(RestSchema.CollabEntity.self, forKey: "entity")
    }

    /// Writes a `CollabLockReleaseSignal` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
      try container.encode(self.entity, forKey: "entity")
    }
  }
}
