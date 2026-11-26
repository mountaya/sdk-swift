// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Stream frame carrying a member's uncommitted draft of an entity they are
  /// editing, so the other members see the edit in progress before it is saved. It
  /// is the broadcast of a draft update signal from the member holding that
  /// entity's soft lock, with the sender's identity stamped on by the server rather
  /// than taken from what the client sent.
  ///
  /// It is live-only: it carries no stream id and is never replayed. A draft is not
  /// the resource, and nothing in it has been saved, so a consumer renders it as a
  /// preview and still reads the resource itself from the change frames.
  public struct CollabDraftUpdateEvent: Sendable, Hashable, Codable {
    /// Always `draft.update` on this event, and the value of the record's
    /// `event:` field. Branch on it to route the event; the enum carries every
    /// type a collaboration stream can send.
    ///
    /// It is always `draft.update`, the discriminator value naming this member of its union.
    public var type: RestSchema.CollabStreamEventType {
      "draft.update"
    }
    /// Which entity the broadcast draft belongs to, by kind and identifier.
    public var entity: RestSchema.CollabEntity
    /// Identifier of the member whose draft this is.
    public var user_id: String
    /// The draft payload, forwarded verbatim from the member who sent it. Its
    /// shape is agreed between the clients sharing the session and is not
    /// interpreted on the way through.
    public var draft: [String: JSONValue]

    /// Creates a `CollabDraftUpdateEvent` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      entity: RestSchema.CollabEntity,
      user_id: String,
      draft: [String: JSONValue],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.entity = entity
      self.user_id = user_id
      self.draft = draft
      configure(&self)
    }

    /// Reads a `CollabDraftUpdateEvent` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.entity = try container.decode(RestSchema.CollabEntity.self, forKey: "entity")
      self.user_id = try container.decode(String.self, forKey: "user_id")
      self.draft = try container.decode([String: JSONValue].self, forKey: "draft")
    }

    /// Writes a `CollabDraftUpdateEvent` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
      try container.encode(self.entity, forKey: "entity")
      try container.encode(self.user_id, forKey: "user_id")
      try container.encode(self.draft, forKey: "draft")
    }
  }
}
