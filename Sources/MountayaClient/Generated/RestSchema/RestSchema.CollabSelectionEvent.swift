// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Stream frame carrying a member's current selection, so the other members can
  /// highlight what their peer is looking at. It is the broadcast of a selection
  /// signal, with the sender's identity stamped on by the server rather than taken
  /// from what the client sent.
  ///
  /// It is live-only: it carries no stream id and is never replayed, so a
  /// reconnecting client learns selections again only as they next move.
  public struct CollabSelectionEvent: Sendable, Hashable, Codable {
    /// Always `selection` on this event, and the value of the record's `event:`
    /// field. Branch on it to route the event; the enum carries every type a
    /// collaboration stream can send.
    ///
    /// It is always `selection`, the discriminator value naming this member of its union.
    public var type: RestSchema.CollabStreamEventType {
      "selection"
    }
    /// Identifier of the member whose selection this is.
    public var user_id: String
    /// The member's selected entity, or null when they cleared it.
    public var selection: RestSchema.CollabSelectionRef?

    /// Creates a `CollabSelectionEvent` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      user_id: String,
      selection: RestSchema.CollabSelectionRef?,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.user_id = user_id
      self.selection = selection
      configure(&self)
    }

    /// Reads a `CollabSelectionEvent` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.user_id = try container.decode(String.self, forKey: "user_id")
      self.selection = try container.decodeIfPresent(
        RestSchema.CollabSelectionRef.self, forKey: "selection")
    }

    /// Writes a `CollabSelectionEvent` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
      try container.encode(self.user_id, forKey: "user_id")
      try container.encodeNullable(self.selection, forKey: "selection")
    }
  }
}
