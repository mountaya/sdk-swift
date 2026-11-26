// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// A built-in overlay layer drawn on top of a terrain base map, such as slope
  /// steepness or snow depth. Carries everything needed to add it to a map: the
  /// tile sources to register and which side of the wire handles each optional
  /// capability.
  public struct Overlay: Sendable, Hashable, Codable {
    /// Which of this overlay's options each side of the wire resolves, so read
    /// this before building the control. Where `server.timestamp` is true, a
    /// tile's `timestamp` selects the instant it depicts. Where it is false, the
    /// instant sent is ignored, and any change over time is the client's to draw
    /// from what it already holds. Two settings are refused. A `timestamp` that
    /// is not an RFC 3339 instant, or that lies more than three days before or
    /// six days after the request, is a `400` on every overlay tile, whether or
    /// not the overlay has a time dimension. Where `server.timestamp` is true, an
    /// instant more than 15 minutes from the current one is a `403` unless the
    /// organization's `with_overlays_control` safety rule allows it, a
    /// share-token request included.
    public var capabilities: RestSchema.OverlayCapabilities
    /// What the overlay's tiles carry, which decides how they are drawn: a raster
    /// overlay is an image layer, a vector one is styled by the layers its
    /// specification declares. For a raster overlay it names the format of the
    /// tiles within its source's zoom range; a tile asked for deeper than that
    /// is cut from its ancestor and is always PNG, so read each tile's
    /// `Content-Type` header rather than this.
    public var content_type: RestSchema.OverlayContentType
    /// Identifier of the overlay. `slug` is the value the Tile API takes; this is
    /// the one the catalog keys on.
    public var id: String
    /// The overlay's display name and blurb per language. A language absent here
    /// is null rather than missing, which is the case to fall back from.
    public var locales: RestSchema.Locales
    /// Stable, URL-safe identifier of the overlay, and the value the Tile API
    /// takes in `/v1/overlays/{overlay}/...`. Lowercase letters, digits and
    /// single hyphens, so it is safe in a path segment without escaping. The
    /// shape is declared here and on that path parameter identically, because a
    /// value this read hands a client is a value that client sends straight back.
    public var slug: String
    /// Tile sources to register with the map renderer before this overlay can be
    /// drawn.
    public var sources: [RestSchema.TileSource]

    /// Creates a `Overlay` from the properties the contract requires, the optional ones being set
    /// in `configure`.
    public init(
      capabilities: RestSchema.OverlayCapabilities,
      content_type: RestSchema.OverlayContentType,
      id: String,
      locales: RestSchema.Locales,
      slug: String,
      sources: [RestSchema.TileSource],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.capabilities = capabilities
      self.content_type = content_type
      self.id = id
      self.locales = locales
      self.slug = slug
      self.sources = sources
      configure(&self)
    }

    /// Reads a `Overlay` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.capabilities = try container.decode(
        RestSchema.OverlayCapabilities.self, forKey: "capabilities")
      self.content_type = try container.decode(
        RestSchema.OverlayContentType.self, forKey: "content_type")
      self.id = try container.decode(String.self, forKey: "id")
      self.locales = try container.decode(RestSchema.Locales.self, forKey: "locales")
      self.slug = try container.decode(String.self, forKey: "slug")
      self.sources = try container.decode([RestSchema.TileSource].self, forKey: "sources")
    }

    /// Writes a `Overlay` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.capabilities, forKey: "capabilities")
      try container.encode(self.content_type, forKey: "content_type")
      try container.encode(self.id, forKey: "id")
      try container.encode(self.locales, forKey: "locales")
      try container.encode(self.slug, forKey: "slug")
      try container.encode(self.sources, forKey: "sources")
    }
  }
}
