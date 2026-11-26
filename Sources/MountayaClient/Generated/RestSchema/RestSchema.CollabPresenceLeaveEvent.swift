// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Stream frame announcing that a member left the session. It is broadcast when
  /// that member's LAST connection closes, so closing one of two tabs announces
  /// nothing. Each soft lock the member still held is released behind it, one
  /// `lock.released` frame each.
  ///
  /// It only arrives for a clean disconnect. A member whose tab was killed or whose
  /// network dropped sends nothing, and their avatar clears instead on the first
  /// presence snapshot after their presence lapses, 45 seconds after their stream
  /// ends.
  ///
  /// The frame carries no timestamp, deliberately. A departure has no join moment
  /// to report, and the field that would have carried one is named for the join.
  public struct CollabPresenceLeaveEvent: Sendable, Hashable, Codable {
    /// Always `presence.leave` on this event, and the value of the record's
    /// `event:` field. Branch on it to route the event; the enum carries every
    /// type a collaboration stream can send.
    ///
    /// It is always `presence.leave`, the discriminator value naming this member of its union.
    public var type: RestSchema.CollabStreamEventType {
      "presence.leave"
    }
    /// Identifier of the member who left.
    public var user_id: String

    /// Creates a `CollabPresenceLeaveEvent` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      user_id: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.user_id = user_id
      configure(&self)
    }

    /// Reads a `CollabPresenceLeaveEvent` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.user_id = try container.decode(String.self, forKey: "user_id")
    }

    /// Writes a `CollabPresenceLeaveEvent` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
      try container.encode(self.user_id, forKey: "user_id")
    }
  }
}
