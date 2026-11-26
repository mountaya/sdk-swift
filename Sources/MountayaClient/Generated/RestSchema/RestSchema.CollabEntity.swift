// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// A lockable collaboration entity: its kind and its identifier. Used by the lock
  /// and draft collaboration signals.
  ///
  /// The kinds are named by CollabEntityKind and are deliberately not restated
  /// here, so this description cannot fall out of step with them. A segment group
  /// is lockable like the rest.
  public struct CollabEntity: Sendable, Hashable, Codable {
    /// Which kind of resource `id` names. The id alone is ambiguous across the
    /// four, so read this before resolving it.
    public var kind: RestSchema.CollabEntityKind
    /// Identifier of the entity, within the kind `kind` names. It is unique per
    /// kind rather than across them, so the pair is what identifies an entity.
    public var id: String

    /// Creates a `CollabEntity` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      kind: RestSchema.CollabEntityKind,
      id: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.kind = kind
      self.id = id
      configure(&self)
    }

    /// Reads a `CollabEntity` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.kind = try container.decode(RestSchema.CollabEntityKind.self, forKey: "kind")
      self.id = try container.decode(String.self, forKey: "id")
    }

    /// Writes a `CollabEntity` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.kind, forKey: "kind")
      try container.encode(self.id, forKey: "id")
    }
  }
}
