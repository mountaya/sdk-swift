// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// A named group of activities in the built-in activity catalog. The group is not
  /// itself selectable: `children` holds the activities a caller can pick, and
  /// `locales` carries the group's display name per language.
  public struct CategoryActivities: Sendable, Hashable, Codable {
    /// The activities in this group. These are the selectable entries; the group
    /// itself is not.
    public var children: [RestSchema.Activity]
    /// Identifier of the activity group.
    public var id: String
    /// The category's display name per language. Render from here rather than
    /// from `slug`: the slug is a stable identifier and is not translated.
    public var locales: RestSchema.Locales
    /// Stable, URL-safe identifier of the activity group. Unlike the display name
    /// in `locales`, it does not change between languages or releases. Lowercase
    /// letters, digits and single hyphens, the same shape every slug on this
    /// surface carries.
    public var slug: String

    /// Creates a `CategoryActivities` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      children: [RestSchema.Activity],
      id: String,
      locales: RestSchema.Locales,
      slug: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.children = children
      self.id = id
      self.locales = locales
      self.slug = slug
      configure(&self)
    }

    /// Reads a `CategoryActivities` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.children = try container.decode([RestSchema.Activity].self, forKey: "children")
      self.id = try container.decode(String.self, forKey: "id")
      self.locales = try container.decode(RestSchema.Locales.self, forKey: "locales")
      self.slug = try container.decode(String.self, forKey: "slug")
    }

    /// Writes a `CategoryActivities` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.children, forKey: "children")
      try container.encode(self.id, forKey: "id")
      try container.encode(self.locales, forKey: "locales")
      try container.encode(self.slug, forKey: "slug")
    }
  }
}
