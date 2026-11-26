// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Stream frame announcing that a member opened the session. It is broadcast to
  /// the other members only on that member's FIRST connection, so opening a second
  /// tab announces nothing.
  ///
  /// It is a delta between snapshots and can only ever add to a roster; the
  /// authoritative set is the presence snapshot.
  public struct CollabPresenceJoinEvent: Sendable, Hashable, Codable {
    /// Always `presence.join` on this event, and the value of the record's
    /// `event:` field. Branch on it to route the event; the enum carries every
    /// type a collaboration stream can send.
    ///
    /// It is always `presence.join`, the discriminator value naming this member of its union.
    public var type: RestSchema.CollabStreamEventType {
      "presence.join"
    }
    /// Identifier of the member who joined.
    public var user_id: String
    /// When the member's session began. Their entry in later presence snapshots
    /// carries the same instant for as long as this first connection stays
    /// open; if it closes while another of theirs stays, the entry moves to the
    /// earliest connection still open.
    public var connected_at: Date

    /// Creates a `CollabPresenceJoinEvent` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      user_id: String,
      connected_at: Date,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.user_id = user_id
      self.connected_at = connected_at
      configure(&self)
    }

    /// Reads a `CollabPresenceJoinEvent` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.user_id = try container.decode(String.self, forKey: "user_id")
      self.connected_at = try container.decodeWired(Date.self, forKey: "connected_at")
    }

    /// Writes a `CollabPresenceJoinEvent` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
      try container.encode(self.user_id, forKey: "user_id")
      try container.encodeWired(self.connected_at, forKey: "connected_at")
    }
  }
}
