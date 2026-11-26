// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// The built-in map layer catalog: the terrain base maps, the grouped overlay
  /// layers, and the two layers that render itineraries and zones. `itineraries`
  /// and `zones` are typed as overlays because that is what they are to a map: one
  /// tile source each, registered the same way. But they are singular and always
  /// present, so they sit beside the `overlays` groups rather than inside them.
  ///
  /// `elevation` is the one entry that draws nothing. It is the height raster the
  /// terrains bake their relief from, and it is always present: the terrains and
  /// the raster they are shaded from are published together, so a catalog that
  /// offers a terrain offers the heights that terrain is drawn against.
  public struct Layers: Sendable, Hashable, Codable {
    /// The height raster a renderer turns into three-dimensional relief. Every
    /// catalog carries one, so a client registers the terrain source
    /// unconditionally rather than branching on whether heights are available.
    public var elevation: RestSchema.Elevation
    /// The single layer that draws the itineraries this credential reaches, in
    /// the studio scope `organization_id` names when the catalog was asked for
    /// one, which its URL template then carries. It is typed as an overlay because that is what it
    /// is to a map, one tile source
    /// registered the same way, and it sits here rather than inside `overlays`
    /// because it is singular and always present: there is one of it, for every
    /// caller, and no group to file it under.
    public var itineraries: RestSchema.Overlay
    /// The overlay catalog, grouped. Each group holds the overlays a caller can
    /// add to a map. Under a publishable key or a share token the overlays a map
    /// draws are the ones the organization's overlay allowlist admits, and the
    /// Tile API holds every overlay tile to it. The Tile API's own catalog,
    /// `getTileLayers`, lists only those, dropping a group left with none; the
    /// Map Studio API's `getLayers` lists every overlay whatever the allowlist
    /// says. From Mountaya's web application both list every overlay, in the
    /// person's own space and in each organization they are a member of, while
    /// the Tile API draws in the studio scope `organization_id` names: the points
    /// of interest alone in the person's own space and in an organization that
    /// does not hold Map Studio, and every overlay in one that does.
    public var overlays: [RestSchema.CategoryOverlays]
    /// The terrain base maps a caller can draw itineraries and zones on.
    public var terrains: [RestSchema.Terrain]
    /// The single layer that draws the zones this credential reaches, in the
    /// studio scope `organization_id` names when the catalog was asked for one,
    /// which its URL template then carries. Typed as an overlay and kept outside
    /// the `overlays` groups for the reason `itineraries` gives.
    public var zones: RestSchema.Overlay

    /// Creates a `Layers` from the properties the contract requires, the optional ones being set in
    /// `configure`.
    public init(
      elevation: RestSchema.Elevation,
      itineraries: RestSchema.Overlay,
      overlays: [RestSchema.CategoryOverlays],
      terrains: [RestSchema.Terrain],
      zones: RestSchema.Overlay,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.elevation = elevation
      self.itineraries = itineraries
      self.overlays = overlays
      self.terrains = terrains
      self.zones = zones
      configure(&self)
    }

    /// Reads a `Layers` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.elevation = try container.decode(RestSchema.Elevation.self, forKey: "elevation")
      self.itineraries = try container.decode(RestSchema.Overlay.self, forKey: "itineraries")
      self.overlays = try container.decode([RestSchema.CategoryOverlays].self, forKey: "overlays")
      self.terrains = try container.decode([RestSchema.Terrain].self, forKey: "terrains")
      self.zones = try container.decode(RestSchema.Overlay.self, forKey: "zones")
    }

    /// Writes a `Layers` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.elevation, forKey: "elevation")
      try container.encode(self.itineraries, forKey: "itineraries")
      try container.encode(self.overlays, forKey: "overlays")
      try container.encode(self.terrains, forKey: "terrains")
      try container.encode(self.zones, forKey: "zones")
    }
  }
}
