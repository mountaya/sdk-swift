// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// A reference to a user by id alone. Resources name their author with this
  /// (`created_by`). No operation resolves an arbitrary user id: a display name
  /// is found by matching the id against `getOrganizationMembers`, which lists the
  /// organization's members with the name each has set, so an author who has
  /// since left the organization, or who never set a name, has none to show.
  public struct RelationToUser: Sendable, Hashable, Codable {
    /// Identifier of the user this relation is about.
    public var id: String

    /// Creates a `RelationToUser` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      id: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.id = id
      configure(&self)
    }

    /// Reads a `RelationToUser` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decode(String.self, forKey: "id")
    }

    /// Writes a `RelationToUser` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.id, forKey: "id")
    }
  }
}
