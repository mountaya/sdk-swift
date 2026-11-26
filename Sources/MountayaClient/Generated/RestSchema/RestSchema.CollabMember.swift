// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// One member present in a collaboration session: who they are, and when their
  /// session began. It is the entry shape inside a presence snapshot, so a client
  /// can render the roster of who else has the resource open.
  public struct CollabMember: Sendable, Hashable, Codable {
    /// Identifier of the member present in the session.
    public var user_id: String
    /// When the member's session began. A member with several tabs open appears
    /// once, timed from the earliest of them, so opening a second tab never moves
    /// their displayed join time forward.
    public var connected_at: Date

    /// Creates a `CollabMember` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      user_id: String,
      connected_at: Date,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.user_id = user_id
      self.connected_at = connected_at
      configure(&self)
    }

    /// Reads a `CollabMember` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.user_id = try container.decode(String.self, forKey: "user_id")
      self.connected_at = try container.decodeWired(Date.self, forKey: "connected_at")
    }

    /// Writes a `CollabMember` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.user_id, forKey: "user_id")
      try container.encodeWired(self.connected_at, forKey: "connected_at")
    }
  }
}
