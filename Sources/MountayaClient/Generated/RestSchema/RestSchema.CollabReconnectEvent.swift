// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Stream frame ending the stream because the credential it was opened with has
  /// ended, the session token having reached its expiry or the key having been
  /// revoked, or because the server could not keep delivering it. It is the last
  /// frame on the stream, and it is not a failure: reopen the stream at once with
  /// `Last-Event-ID`, and a fresh session token where the credential ended, and the
  /// durable frames written in between are replayed. A reopen answered `401` means
  /// the credential itself is gone, and the stream ends there.
  ///
  /// It carries no id and is never replayed.
  public struct CollabReconnectEvent: Sendable, Hashable, Codable {
    /// Always `reconnect` on this event, and the value of the record's `event:`
    /// field. Branch on it to route the event; the enum carries every type a
    /// collaboration stream can send.
    ///
    /// It is always `reconnect`, the discriminator value naming this member of its union.
    public var type: RestSchema.CollabStreamEventType {
      "reconnect"
    }
    /// Which way the stream ended: how the credential ended, or `interrupted`.
    public var reason: RestSchema.StreamReconnectReason

    /// Creates a `CollabReconnectEvent` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      reason: RestSchema.StreamReconnectReason,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.reason = reason
      configure(&self)
    }

    /// Reads a `CollabReconnectEvent` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.reason = try container.decode(RestSchema.StreamReconnectReason.self, forKey: "reason")
    }

    /// Writes a `CollabReconnectEvent` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
      try container.encode(self.reason, forKey: "reason")
    }
  }
}
