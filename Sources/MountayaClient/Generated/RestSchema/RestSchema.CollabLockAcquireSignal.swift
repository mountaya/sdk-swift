// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Collaboration signal requesting the soft edit lock on an entity. On success
  /// the server broadcasts a lock.acquired event; when another member already holds
  /// the lock the request is refused with 409 Conflict naming the holder.
  ///
  /// A lock lasts 60 seconds from the acquire. The member's open editor stream
  /// for the resource keeps it alive for as long as that connection lasts, and
  /// sending this signal again renews it; without either, it lapses. A lapse
  /// produces no `lock.released`: the next `lock.snapshot` stops listing the
  /// lock, and a draft signal on the entity is then refused with 409 naming the
  /// all-zero holder.
  public struct CollabLockAcquireSignal: Sendable, Hashable, Codable {
    /// Always `lock.acquire` on this signal, and what the server routes it on.
    /// The enum carries every signal a client may send on a collaboration
    /// session.
    ///
    /// It is always `lock.acquire`, the discriminator value naming this member of its union.
    public var type: RestSchema.CollabSignalType {
      "lock.acquire"
    }
    /// Which entity to take the lock on, by kind and identifier.
    public var entity: RestSchema.CollabEntity

    /// Creates a `CollabLockAcquireSignal` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      entity: RestSchema.CollabEntity,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.entity = entity
      configure(&self)
    }

    /// Reads a `CollabLockAcquireSignal` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.entity = try container.decode(RestSchema.CollabEntity.self, forKey: "entity")
    }

    /// Writes a `CollabLockAcquireSignal` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
      try container.encode(self.entity, forKey: "entity")
    }
  }
}
