// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Collaboration signal broadcasting the caller's cursor position to the other
  /// members viewing the itinerary, and back to the caller's own connections. A
  /// null position clears it. The server stamps the caller's user id onto the
  /// broadcast; a client-supplied user id is never trusted.
  public struct CollabCursorSignal: Sendable, Hashable, Codable {
    /// Always `cursor` on this signal, and what the server routes it on. The enum
    /// carries every signal a client may send on a collaboration session.
    ///
    /// It is always `cursor`, the discriminator value naming this member of its union.
    public var type: RestSchema.CollabSignalType {
      "cursor"
    }
    /// The cursor position, or null to clear the caller's cursor.
    public var position: RestSchema.CollabPosition?

    /// Creates a `CollabCursorSignal` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      position: RestSchema.CollabPosition?,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.position = position
      configure(&self)
    }

    /// Reads a `CollabCursorSignal` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.position = try container.decodeIfPresent(
        RestSchema.CollabPosition.self, forKey: "position")
    }

    /// Writes a `CollabCursorSignal` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
      try container.encodeNullable(self.position, forKey: "position")
    }
  }
}
