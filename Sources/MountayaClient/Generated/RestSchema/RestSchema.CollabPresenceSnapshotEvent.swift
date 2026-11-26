// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Stream frame carrying the authoritative set of members present in the session,
  /// including the caller. It is written to a connection when it opens and
  /// re-written down that same connection every few seconds; it is never broadcast
  /// and never replayed. The one written on connect can be up to one interval old,
  /// and so can miss the caller's own arrival; the next one is current.
  ///
  /// A consumer replaces its roster wholesale from it. That is what lets the avatar
  /// of a peer who vanished without a clean disconnect (a killed tab, a dropped
  /// network) disappear once its presence lapses, 45 seconds after its stream
  /// ends, which no join or leave frame could ever do on its own.
  public struct CollabPresenceSnapshotEvent: Sendable, Hashable, Codable {
    /// Always `presence.snapshot` on this event, and the value of the record's
    /// `event:` field. Branch on it to route the event; the enum carries every
    /// type a collaboration stream can send.
    ///
    /// It is always `presence.snapshot`, the discriminator value naming this member of its union.
    public var type: RestSchema.CollabStreamEventType {
      "presence.snapshot"
    }
    /// Every member present, one entry each however many tabs they have
    /// open. Always an array, empty rather than null when nobody is present.
    public var members: [RestSchema.CollabMember]

    /// Creates a `CollabPresenceSnapshotEvent` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      members: [RestSchema.CollabMember],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.members = members
      configure(&self)
    }

    /// Reads a `CollabPresenceSnapshotEvent` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.members = try container.decode([RestSchema.CollabMember].self, forKey: "members")
    }

    /// Writes a `CollabPresenceSnapshotEvent` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
      try container.encode(self.members, forKey: "members")
    }
  }
}
