// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Stream frame carrying the authoritative set of soft edit locks held on the
  /// resource. It is written to a connection when it opens and re-written down that
  /// same connection every few seconds, alongside the presence snapshot; it is
  /// never broadcast and never replayed.
  ///
  /// A consumer replaces its lock state wholesale from it. That is what lets a
  /// badge left behind by a peer who vanished without a clean disconnect clear once
  /// their lock lapses, which no acquire or release frame could ever do on its own.
  public struct CollabLockSnapshotEvent: Sendable, Hashable, Codable {
    /// Always `lock.snapshot` on this event, and the value of the record's
    /// `event:` field. Branch on it to route the event; the enum carries every
    /// type a collaboration stream can send.
    ///
    /// It is always `lock.snapshot`, the discriminator value naming this member of its union.
    public var type: RestSchema.CollabStreamEventType {
      "lock.snapshot"
    }
    /// Every soft edit lock held on the resource. Always an array,
    /// empty rather than null when nothing is locked: a consumer that applies the
    /// set wholesale has to be able to clear its own.
    public var locks: [RestSchema.CollabLock]

    /// Creates a `CollabLockSnapshotEvent` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      locks: [RestSchema.CollabLock],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.locks = locks
      configure(&self)
    }

    /// Reads a `CollabLockSnapshotEvent` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.locks = try container.decode([RestSchema.CollabLock].self, forKey: "locks")
    }

    /// Writes a `CollabLockSnapshotEvent` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
      try container.encode(self.locks, forKey: "locks")
    }
  }
}
