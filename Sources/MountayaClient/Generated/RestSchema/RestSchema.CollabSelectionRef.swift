// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// A selected collaboration entity: its kind (segment or waypoint) and its
  /// identifier. Null when the collaborator has nothing selected.
  public struct CollabSelectionRef: Sendable, Hashable, Codable {
    /// Which kind of resource `id` names. A selection reaches segments and
    /// waypoints only, which is why this is narrower than the entity kind a lock
    /// carries.
    public var kind: RestSchema.CollabSelectionKind
    /// Identifier of the selected entity.
    public var id: String

    /// Creates a `CollabSelectionRef` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      kind: RestSchema.CollabSelectionKind,
      id: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.kind = kind
      self.id = id
      configure(&self)
    }

    /// Reads a `CollabSelectionRef` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.kind = try container.decode(RestSchema.CollabSelectionKind.self, forKey: "kind")
      self.id = try container.decode(String.self, forKey: "id")
    }

    /// Writes a `CollabSelectionRef` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.kind, forKey: "kind")
      try container.encode(self.id, forKey: "id")
    }
  }
}
