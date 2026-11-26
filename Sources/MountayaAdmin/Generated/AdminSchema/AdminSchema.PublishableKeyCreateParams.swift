// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A new publishable key. Both fields are required: a key with no scopes reaches
  /// nothing, so there is no useful default to fall back on, and an empty `scopes`
  /// list is a 400. The key is given exactly the scopes listed: none is added
  /// because another is present.
  public struct PublishableKeyCreateParams: Sendable, Hashable, Codable {
    /// Display name of the publishable key: 2 to 30 characters as sent, and still
    /// at least 2 once leading and trailing whitespace is trimmed, which is the
    /// form it is stored in. A name is one line: a tab, a line break or a line
    /// separator between two of its characters is a `400`, and one at either end
    /// is trimmed with the whitespace there.
    public var name: String
    /// The scopes to give the key, each at most once. A key carries at least
    /// one: an empty list is a `400` naming `scopes`. A scope is granted only
    /// while the organization holds its product, so one it does not hold is a
    /// `402` naming its position in the list. `management` is carried alone:
    /// a list naming it beside another scope is a `400` naming the position of
    /// each scope beside it. `studio-embedded` is carried with `tiles` and
    /// `data`: a list naming it without one of them is a `400` naming
    /// `scopes`, once per missing scope.
    public var scopes: [AdminSchema.PublishableKeyScope]

    /// Creates a `PublishableKeyCreateParams` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      name: String,
      scopes: [AdminSchema.PublishableKeyScope],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.name = name
      self.scopes = scopes
      configure(&self)
    }

    /// Reads a `PublishableKeyCreateParams` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.name = try container.decode(String.self, forKey: "name")
      self.scopes = try container.decode([AdminSchema.PublishableKeyScope].self, forKey: "scopes")
    }

    /// Writes a `PublishableKeyCreateParams` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.name, forKey: "name")
      try container.encode(self.scopes, forKey: "scopes")
    }
  }
}
