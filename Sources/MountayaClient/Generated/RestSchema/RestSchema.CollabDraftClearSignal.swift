// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Collaboration signal clearing the caller's uncommitted draft for an entity.
  /// The caller must already hold the entity's soft lock; a clear from a non-holder
  /// is refused with 409 Conflict. The server stamps the caller's user id onto the
  /// broadcast; a client-supplied user id is never trusted.
  public struct CollabDraftClearSignal: Sendable, Hashable, Codable {
    /// Always `draft.clear` on this signal, and what the server routes it on. The
    /// enum carries every signal a client may send on a collaboration session.
    ///
    /// It is always `draft.clear`, the discriminator value naming this member of its union.
    public var type: RestSchema.CollabSignalType {
      "draft.clear"
    }
    /// Which entity's draft to clear, by kind and identifier. The caller must
    /// already hold this entity's lock.
    public var entity: RestSchema.CollabEntity

    /// Creates a `CollabDraftClearSignal` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      entity: RestSchema.CollabEntity,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.entity = entity
      configure(&self)
    }

    /// Reads a `CollabDraftClearSignal` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.entity = try container.decode(RestSchema.CollabEntity.self, forKey: "entity")
    }

    /// Writes a `CollabDraftClearSignal` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
      try container.encode(self.entity, forKey: "entity")
    }
  }
}
