// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Stream frame carrying a member's cursor position on the map, so the other
  /// members can render a live pointer for their peer. It is the broadcast of a
  /// cursor signal, with the sender's identity stamped on by the server rather than
  /// taken from what the client sent.
  ///
  /// It is live-only: it carries no stream id and is never replayed. It is also the
  /// highest-rate frame on the stream, so a consumer is expected to throttle what
  /// it renders rather than to redraw on each one.
  public struct CollabCursorEvent: Sendable, Hashable, Codable {
    /// Always `cursor` on this event, and the value of the record's `event:`
    /// field. Branch on it to route the event; the enum carries every type a
    /// collaboration stream can send.
    ///
    /// It is always `cursor`, the discriminator value naming this member of its union.
    public var type: RestSchema.CollabStreamEventType {
      "cursor"
    }
    /// Identifier of the member whose cursor this is.
    public var user_id: String
    /// The member's cursor position, or null when their cursor left the canvas.
    public var position: RestSchema.CollabPosition?

    /// Creates a `CollabCursorEvent` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      user_id: String,
      position: RestSchema.CollabPosition?,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.user_id = user_id
      self.position = position
      configure(&self)
    }

    /// Reads a `CollabCursorEvent` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.user_id = try container.decode(String.self, forKey: "user_id")
      self.position = try container.decodeIfPresent(
        RestSchema.CollabPosition.self, forKey: "position")
    }

    /// Writes a `CollabCursorEvent` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
      try container.encode(self.user_id, forKey: "user_id")
      try container.encodeNullable(self.position, forKey: "position")
    }
  }
}
