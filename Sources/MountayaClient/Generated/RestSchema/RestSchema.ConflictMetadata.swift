// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Metadata returned with a 409 Conflict response. Contains the identifier of
  /// what the write conflicted with: the existing resource that already carries
  /// the name it asked for, or, on a write refused for a soft lock, the member
  /// holding that lock.
  public struct ConflictMetadata: Sendable, Hashable, Codable {
    /// Identifier of the conflicting resource, or of the member holding the
    /// lock. The response metadata that carries it says which.
    public var id: String

    /// Creates a `ConflictMetadata` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      id: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.id = id
      configure(&self)
    }

    /// Reads a `ConflictMetadata` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decode(String.self, forKey: "id")
    }

    /// Writes a `ConflictMetadata` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.id, forKey: "id")
    }
  }
}
