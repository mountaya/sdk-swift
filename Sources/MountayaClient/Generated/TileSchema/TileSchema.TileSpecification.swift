// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension TileSchema {
  /// Rendering specification for a tile resource. Returned by every
  /// `/specification` endpoint and consumed once while a map is initializing:
  /// iterate `sources` and call `map.addSource()` for each, then iterate the
  /// `layers` inside each source and call `map.addLayer()` for each. The map
  /// library then fetches the `{z}/{x}/{y}` tiles automatically. A collection's
  /// specification also carries `bbox`, the extent of the itineraries its tiles
  /// draw, which is where to fit the camera once the sources are registered.
  ///
  /// Served to a publishable key, every `zoom_min` and `zoom_max` in it is already
  /// narrowed to the organization's zoom-bounds safety rule, so a map that follows
  /// it asks only for tiles that rule serves. A layer's range is intersected with
  /// the bounds, and a layer whose range lies wholly outside them is left out, as
  /// is a source left with no layer. A source's own range is clamped into the
  /// bounds rather than intersected, so a source whose tiles stop below the
  /// bounds still reports a range inside them, and the tiles past its own ceiling
  /// are cut from their ancestors.
  public struct TileSpecification: Sendable, Hashable, Codable {
    /// The extent of the itineraries this specification's tiles draw, as
    /// [west, south, east, north] in WGS 84 decimal degrees. This is the flat
    /// four-tuple every bounding box on every Mountaya surface uses. Exactly four
    /// numbers, longitude first in each pair, every longitude between -180 and
    /// 180.
    ///
    /// Of the two boxes the longitudes allow, read as written and read across
    /// the antimeridian, it is the narrower, the one as written when they are
    /// as wide. One across the antimeridian has west greater than east, as RFC
    /// 7946 section 5.2 writes such a box: itineraries near 179.8 and -179.9
    /// degrees answer `[179.8, s, -179.9, n]`, a box 0.3 degrees wide, rather
    /// than the 359.7 degrees the same longitudes span as written. Any other
    /// box this answers has west at or below east, the minimum corner first. A
    /// map library that takes a box only with west below east, MapLibre's
    /// `fitBounds()` among them, is handed east plus 360 for one that crosses:
    /// `[179.8, s, 180.1, n]`.
    ///
    /// Fit the map's camera to it once the sources are registered, with
    /// MapLibre's `fitBounds()` for instance, so the map opens on every
    /// itinerary the tiles draw rather than on the `center` and `zoom` it was
    /// created with. When it is null there is nothing to fit to, and the map
    /// keeps its own camera.
    ///
    /// Carried by a collection's specification and by no other: every other
    /// specification leaves it out. On a collection's it is always present. It
    /// spans every line and point of the collection's itineraries that its
    /// tiles draw for the same credential, the same `surface` and the same
    /// resolved `with_itineraries`, each as it is drawn: under a publishable
    /// key alone, and under a key with a session token minted without
    /// `user_id`, the public ones of the key's organization, as last
    /// published; under a key with a session token naming a member, every one
    /// the key's organization owns, as its draft, or as last published when
    /// `surface=published` asks for the published snapshots; under a
    /// collection share token, every one the collection holds, as last
    /// published. Zones never count toward it, drawn or not. It is not clipped
    /// to the organization's geographic boundaries, so under a publishable key
    /// it can reach past them, where a tile is refused.
    ///
    /// Null when none of those itineraries is drawn: the collection holds none
    /// this credential is served, none it is served has a geometry yet, or
    /// `with_itineraries` resolves to off, which on a publishable-key request
    /// includes the organization's safety rule keeping collection itineraries
    /// off. Under a key, another organization's collection draws none, so its
    /// box is null.
    public var bbox: [Double]?
    /// Map sources to register, in order. Each becomes one `map.addSource()` call
    /// and carries the render-layers to draw from it.
    public var sources: [TileSchema.TileSource]

    /// Creates a `TileSpecification` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      sources: [TileSchema.TileSource],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.bbox = nil
      self.sources = sources
      configure(&self)
    }

    /// Reads a `TileSpecification` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.bbox = try container.decodeIfPresent([Double].self, forKey: "bbox")
      self.sources = try container.decode([TileSchema.TileSource].self, forKey: "sources")
    }

    /// Writes a `TileSpecification` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.bbox, forKey: "bbox")
      try container.encode(self.sources, forKey: "sources")
    }
  }
}
