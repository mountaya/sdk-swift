// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// An outdoor activity type with its capabilities.
  public struct Activity: Sendable, Hashable, Codable {
    /// What the routing engine can do for this activity. Read it before offering
    /// a mode: an activity that cannot be routed accepts linestring segments
    /// only, and a client that offers directions anyway produces a request the
    /// server refuses.
    public var capabilities: RestSchema.ActivityCapabilities
    /// Unique identifier of the activity.
    public var id: String
    /// The activity's display name per language. Render from here rather than
    /// from `slug`: the slug is a stable identifier and is not translated.
    public var locales: RestSchema.Locales
    /// Stable identifier for the activity, the same on every surface and safe to
    /// store. `id` is the value operations take; this is the value a human reads
    /// in a URL or a config file.
    public var slug: RestSchema.ActivitySlug

    /// Creates a `Activity` from the properties the contract requires, the optional ones being set
    /// in `configure`.
    public init(
      capabilities: RestSchema.ActivityCapabilities,
      id: String,
      locales: RestSchema.Locales,
      slug: RestSchema.ActivitySlug,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.capabilities = capabilities
      self.id = id
      self.locales = locales
      self.slug = slug
      configure(&self)
    }

    /// Reads a `Activity` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.capabilities = try container.decode(
        RestSchema.ActivityCapabilities.self, forKey: "capabilities")
      self.id = try container.decode(String.self, forKey: "id")
      self.locales = try container.decode(RestSchema.Locales.self, forKey: "locales")
      self.slug = try container.decode(RestSchema.ActivitySlug.self, forKey: "slug")
    }

    /// Writes a `Activity` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.capabilities, forKey: "capabilities")
      try container.encode(self.id, forKey: "id")
      try container.encode(self.locales, forKey: "locales")
      try container.encode(self.slug, forKey: "slug")
    }
  }
}
