// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Collaboration signal broadcasting the caller's current selection to the other
  /// members viewing the itinerary, and back to the caller's own connections. A
  /// null selection clears it. The server stamps the caller's user id onto the
  /// broadcast; a client-supplied user id is never trusted.
  public struct CollabSelectionSignal: Sendable, Hashable, Codable {
    /// Always `selection` on this signal, and what the server routes it on. The
    /// enum carries every signal a client may send on a collaboration session.
    ///
    /// It is always `selection`, the discriminator value naming this member of its union.
    public var type: RestSchema.CollabSignalType {
      "selection"
    }
    /// The selected entity, or null to clear the caller's selection.
    public var selection: RestSchema.CollabSelectionRef?

    /// Creates a `CollabSelectionSignal` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      selection: RestSchema.CollabSelectionRef?,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.selection = selection
      configure(&self)
    }

    /// Reads a `CollabSelectionSignal` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.selection = try container.decodeIfPresent(
        RestSchema.CollabSelectionRef.self, forKey: "selection")
    }

    /// Writes a `CollabSelectionSignal` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
      try container.encodeNullable(self.selection, forKey: "selection")
    }
  }
}
