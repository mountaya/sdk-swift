// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

/// TileTemplates is every route of the Tile API a map renderer fetches on its own, the tiles and
/// the base map's style, TileJSON, sprite and glyph documents: URL templates, resolved against the
/// surface's origin, which no method binds.
public enum TileTemplates {
  /// all is every template, in the model's order.
  public static let all: [URLTemplate] = [
    getCollectionTile,
    getElevationTile,
    getElevationTileJson,
    getItinerariesTile,
    getItineraryTile,
    getOverlayTile,
    getTerrainGlyph,
    getTerrainSourceTile,
    getTerrainSprite,
    getTerrainStyle,
    getTerrainTile,
    getTerrainTileJson,
    getZonesTile,
  ]

  /// Retrieve a vector tile of a collection's itineraries and zones.
  ///
  /// Returns a vector tile for a collection at the given zoom level, x, and y
  /// coordinates. The response is Mapbox Vector Tile (MVT) binary data containing
  /// the zones and itineraries tied to the collection that this credential could
  /// list: under a publishable key alone, the organization's public itineraries
  /// and zones, each as last published, so a member never published draws
  /// nothing, and the same under a key with a session token minted without
  /// `user_id`; with a session token naming a member, every member the key's
  /// organization owns, as drafts unless `surface=published` asks for the
  /// published snapshots; under a collection share token, the itineraries and
  /// zones that collection contains, each as last published. Another
  /// organization's public collection is reachable, but its tile draws nothing.
  ///
  /// Collection tiles are returned as vector data. They must be used as a
  /// `vector` source. The tile carries exactly four source-layers: `fills` for
  /// zones, and `itinerary_lines`, `itinerary_points` and
  /// `itinerary_restrictions` for itineraries. A publishable-key request for a
  /// tile outside the organization's zoom bounds or geographic boundaries is a
  /// `400`.
  ///
  /// `itinerary_restrictions` carries, from zoom 9, one line feature for
  /// each stretch of a segment's `road_access_info` that restricts who may
  /// pass: the segment's line cut between the stretch's two indexes, never
  /// across two of its lines. A feature carries `segment_id`, `itinerary_id`
  /// and `kind`, the most severe of the stretch's restrictions: `forbidden`
  /// for `no`, `private` for `private`, `permit` for `permit`, `service` for
  /// `service`, `local-access` for `destination`, `customers` and `delivery`,
  /// and `restricted` for `restricted`, `unknown` and any value this list does
  /// not name. A stretch whose restrictions are only `permissive`,
  /// `agricultural` or `forestry` has no kind and is not drawn. The
  /// specification declares no layer for it: a map that draws restricted
  /// stretches adds layers of its own over it, as `@mountaya/elements` does.
  ///
  /// In `fills`, a zone is one feature for each of its polygons. A feature's
  /// geometry is that polygon clipped exactly to a window around the tile,
  /// however intricate it is, from two tiles' width before its square to one
  /// tile's width past it, -8192 to 8191 in the tile's 4,096-unit coordinates,
  /// so it may extend past the tile's square and is not the zone's whole
  /// outline. Draw it clipped to the tile, as a map library does, and take a
  /// zone's outline from the zone itself, never from a tile. A zone stored
  /// before outlines were checked on write is checked by Mountaya shortly
  /// after the release; until it has been, and for good when its outline breaks
  /// a rule a write now holds it to (a valid polygon, at most 10,000 positions,
  /// no meridian or parallel crossing it more than 512 times, which a zone
  /// computed from a source was not held to), it is carried as it is stored and
  /// approximated where it passes through that window many times. The work of one tile is bounded:
  /// a tile whose zones take longer than that to draw is the `504` of a spent
  /// budget.
  ///
  /// A zone drawn from its draft carries its `id`, `name`, `level`, `mode`,
  /// `is_private`, `revision` and `created_by` as properties, and its
  /// `organization_id`, `description`, `start_at` and `end_at` when it has them: a
  /// personal zone, owned by no organization, carries no `organization_id`. A zone
  /// drawn from its publication carries what a published itinerary does: its
  /// `id`, `name`, `level` and `mode`, and its `description`, `start_at` and
  /// `end_at` when the publication has them, never who made it, which
  /// organization holds it, its privacy or its revision. The two bounds are Unix
  /// seconds, so a style can filter on a zone's validity window.
  ///
  /// Details for consuming a collection can be found in [the specification
  /// endpoint](#tag/Collections/paths/~1v1~1collections~1{collection_id}~1specification/get).
  ///
  /// This route is consumed as a URL template rather than called directly. The
  /// matching specification endpoint returns it under `sources[].tiles` with the
  /// `{z}`, `{x}` and `{y}` placeholders intact, and a map library (MapLibre GL JS,
  /// Mapbox GL JS, or `@mountaya/elements`) expands and fetches them on its own
  /// schedule. The generated SDKs bind no method for it.
  ///
  /// A publishable key needs the `tiles` scope, or `publishing` on a request from
  /// a page on Mountaya's own domain. A share token carries its own authority and
  /// needs none.
  public static let getCollectionTile = URLTemplate(
    operationId: "getCollectionTile",
    path: "/v1/collections/{collection_id}/{z}/{x}/{y}",
    pathParameters: ["collection_id", "z", "x", "y"],
    queryParameters: ["timestamp", "surface", "itinerary_id", "with_zones", "with_itineraries"],
    mediaTypes: ["application/x-protobuf"]
  )

  /// Retrieve a tile of the elevation raster.
  ///
  /// Returns one tile of the elevation raster at the given zoom level, x and y
  /// coordinates: an image whose pixels encode height rather than colour, in the
  /// `encoding` the elevation TileJSON document, `getElevationTileJson`, names.
  /// It is that document's `tiles` template, with the `{z}`, `{x}` and `{y}`
  /// placeholders intact, and a map renderer expands and fetches it on its own
  /// schedule, so the generated SDKs bind no method for it.
  ///
  /// Mountaya fetches it from its base-map provider and answers it with every
  /// address it holds rewritten to point at this API, so a map renderer reaches
  /// the whole base map here, under the credential it sends here, and no answer
  /// carries a credential of Mountaya's.
  ///
  /// A publishable key needs the `tiles` scope, or `publishing` on a request from
  /// a page on Mountaya's own domain, exactly as an overlay tile does. A share
  /// token carries its own authority and needs none. A session token beside the
  /// key changes nothing about what is served: a base map is the same for every
  /// caller.
  ///
  /// Recorded as the organization's Tile API usage under the resource type
  /// `terrain`, on the surface the request comes from, and never counted toward
  /// the organization's per-minute limit or its monthly allowance: a base map is
  /// the frame every other layer is drawn in, and drawing it is Mountaya's cost
  /// rather than the organization's, so a spent monthly allowance never
  /// refuses it either. One bound holds it instead, on every surface and in
  /// place of the surface's others: 6,000 a minute per client IP address, policy
  /// `"address"`, and a request past it is a `429` with `Retry-After`. The
  /// organization's zoom bounds and geographic boundaries do not apply to it.
  public static let getElevationTile = URLTemplate(
    operationId: "getElevationTile",
    path: "/v1/elevation/{z}/{x}/{y}",
    pathParameters: ["z", "x", "y"],
    queryParameters: [],
    mediaTypes: ["image/webp", "image/png"]
  )

  /// Retrieve the elevation raster as a TileJSON tile source.
  ///
  /// Returns the elevation raster a renderer reads heights out of as a
  /// `raster-dem` source described by a TileJSON document, with the
  /// `encoding` its pixels are decoded with. It is the address the layer catalog
  /// answers under `elevation.url`, so a client reads it from the catalog rather
  /// than writing it.
  ///
  /// Mountaya fetches it from its base-map provider and answers it with every
  /// address it holds rewritten to point at this API, so a map renderer reaches
  /// the whole base map here, under the credential it sends here, and no answer
  /// carries a credential of Mountaya's. The document's `tiles` template is
  /// `getElevationTile`.
  ///
  /// The answer is the TileJSON document itself, not wrapped in this API's
  /// envelope, because a renderer reads it as it arrives. This route is consumed
  /// as an address handed to a map renderer rather than called directly, so the
  /// generated SDKs bind no method for it.
  ///
  /// A publishable key needs the `tiles` scope, or `publishing` on a request from
  /// a page on Mountaya's own domain, exactly as an overlay tile does. A share
  /// token carries its own authority and needs none. A session token beside the
  /// key changes nothing about what is served: a base map is the same for every
  /// caller.
  ///
  /// Recorded as the organization's Tile API usage under the resource type
  /// `terrain`, on the surface the request comes from, and never counted toward
  /// the organization's per-minute limit or its monthly allowance: a base map is
  /// the frame every other layer is drawn in, and drawing it is Mountaya's cost
  /// rather than the organization's, so a spent monthly allowance never
  /// refuses it either. One bound holds it instead, on every surface and in
  /// place of the surface's others: 6,000 a minute per client IP address, policy
  /// `"address"`, and a request past it is a `429` with `Retry-After`. The
  /// organization's zoom bounds and geographic boundaries do not apply to it.
  public static let getElevationTileJson = URLTemplate(
    operationId: "getElevationTileJson",
    path: "/v1/elevation/tiles.json",
    pathParameters: [],
    queryParameters: [],
    mediaTypes: ["application/json"]
  )

  /// Retrieve a vector tile of the organization's itineraries.
  ///
  /// Returns a vector tile of the organization's itineraries at the given zoom
  /// level, x, and y coordinates. The response is Mapbox Vector Tile (MVT) binary
  /// data. The itineraries it draws are the ones `getItineraries` lists for the
  /// same credential: the organization's public itineraries as last published
  /// under a key alone or with a session token minted without `user_id`; its
  /// public and private itineraries as drafts when a session token naming a
  /// member accompanies the key; and none under a share token, which is answered
  /// an empty tile. A publishable-key request for a tile outside the
  /// organization's zoom bounds or geographic boundaries is a `400`.
  ///
  /// The optional `organization_id` names the studio scope the tile is drawn
  /// in. Under a publishable key or a share token it may name only the
  /// credential's own organization and changes nothing. From Mountaya's web
  /// application it chooses which itineraries are drawn: the person's own,
  /// which belong to no organization, when it is omitted, and the itineraries
  /// of an organization the person is a member of when it names one, never
  /// those of another space the person belongs to. A map that follows the layer
  /// catalog sends the value the catalog was served for, because the itinerary
  /// layer's URL template carries it.
  ///
  /// Itinerary tiles are returned as vector data. They must be used as a `vector`
  /// source. Three source layers are exposed: `itinerary_lines` for segment
  /// geometries, `itinerary_points` for both true waypoints and the derived
  /// per-itinerary start and end markers, and `itinerary_restrictions` for the
  /// stretches of a segment that follow a way restricting who may pass. Every
  /// point feature carries `icon` and `color` so a single symbol layer keyed on
  /// `section-icon-<icon>-<hex>` covers waypoints (each waypoint's own `icon`)
  /// and the endpoint markers (`icon = 'flag-start' | 'flag-end'`). Endpoint
  /// marker features also carry an informational `marker_role` (`start` / `end`)
  /// that is absent on waypoints and can be used to disambiguate clicks; it is
  /// not needed for rendering.
  ///
  /// `itinerary_restrictions` carries, from zoom 9, one line feature for
  /// each stretch of a segment's `road_access_info` that restricts who may
  /// pass: the segment's line cut between the stretch's two indexes, never
  /// across two of its lines. A feature carries `segment_id`, `itinerary_id`
  /// and `kind`, the most severe of the stretch's restrictions: `forbidden`
  /// for `no`, `private` for `private`, `permit` for `permit`, `service` for
  /// `service`, `local-access` for `destination`, `customers` and `delivery`,
  /// and `restricted` for `restricted`, `unknown` and any value this list does
  /// not name. A stretch whose restrictions are only `permissive`,
  /// `agricultural` or `forestry` has no kind and is not drawn. The
  /// specification declares no layer for it: a map that draws restricted
  /// stretches adds layers of its own over it, as `@mountaya/elements` does.
  ///
  /// Details for consuming itineraries can be found in [the specification
  /// endpoint](#tag/Itineraries/paths/~1v1~1itineraries~1specification/get).
  ///
  /// This route is consumed as a URL template rather than called directly. The
  /// matching specification endpoint returns it under `sources[].tiles` with the
  /// `{z}`, `{x}` and `{y}` placeholders intact, and a map library (MapLibre GL JS,
  /// Mapbox GL JS, or `@mountaya/elements`) expands and fetches them on its own
  /// schedule. The generated SDKs bind no method for it.
  ///
  /// A publishable key needs the `tiles` scope, or `publishing` on a request from
  /// a page on Mountaya's own domain. A share token carries its own authority and
  /// needs none.
  public static let getItinerariesTile = URLTemplate(
    operationId: "getItinerariesTile",
    path: "/v1/itineraries/{z}/{x}/{y}",
    pathParameters: ["z", "x", "y"],
    queryParameters: ["surface", "organization_id"],
    mediaTypes: ["application/x-protobuf"]
  )

  /// Retrieve a vector tile of a single itinerary.
  ///
  /// Returns a vector tile for a single itinerary at the given zoom level, x,
  /// and y coordinates. The response is Mapbox Vector Tile (MVT) binary data.
  ///
  /// Itinerary tiles contain three source layers: `itinerary_lines` for line
  /// geometries, `itinerary_points` for point geometries (waypoints and the
  /// per-itinerary endpoint markers), and `itinerary_restrictions` for the
  /// stretches of a segment that follow a way restricting who may pass. A
  /// publishable-key request for a tile outside the organization's zoom bounds
  /// is a `400`; this route is not held to the geographic boundaries.
  ///
  /// `itinerary_restrictions` carries, from zoom 9, one line feature for
  /// each stretch of a segment's `road_access_info` that restricts who may
  /// pass: the segment's line cut between the stretch's two indexes, never
  /// across two of its lines. A feature carries `segment_id`, `itinerary_id`
  /// and `kind`, the most severe of the stretch's restrictions: `forbidden`
  /// for `no`, `private` for `private`, `permit` for `permit`, `service` for
  /// `service`, `local-access` for `destination`, `customers` and `delivery`,
  /// and `restricted` for `restricted`, `unknown` and any value this list does
  /// not name. A stretch whose restrictions are only `permissive`,
  /// `agricultural` or `forestry` has no kind and is not drawn. The
  /// specification declares no layer for it: a map that draws restricted
  /// stretches adds layers of its own over it, as `@mountaya/elements` does.
  ///
  /// Details for consuming an itinerary tile can be found in [the specification
  /// endpoint](#tag/Itineraries/paths/~1v1~1itineraries~1{itinerary_id}~1specification/get).
  ///
  /// This route is consumed as a URL template rather than called directly. The
  /// matching specification endpoint returns it under `sources[].tiles` with the
  /// `{z}`, `{x}` and `{y}` placeholders intact, and a map library (MapLibre GL JS,
  /// Mapbox GL JS, or `@mountaya/elements`) expands and fetches them on its own
  /// schedule. The generated SDKs bind no method for it.
  ///
  /// A publishable key needs the `tiles` scope, or `publishing` on a request from
  /// a page on Mountaya's own domain. A share token carries its own authority and
  /// needs none.
  ///
  /// Refused with 403 when `surface=published` names a PERSONAL itinerary, that
  /// is, one owned by no organization. The published-surface opt-in is how the
  /// studio's video and embed previews read the tiles of an itinerary, and a
  /// video and an embed are outputs of an organization's products, which a
  /// personal itinerary, owned by none, never has, whatever the credential. A
  /// request without the opt-in is not refused this way. Only the person whose
  /// itinerary it is reads it as its draft and is refused this way; every other
  /// caller, every publishable key included, reads it as published, is served
  /// nothing of a personal itinerary, which is never published, and is answered
  /// `404` before this refusal is reached, as a caller who cannot view it is.
  public static let getItineraryTile = URLTemplate(
    operationId: "getItineraryTile",
    path: "/v1/itineraries/{itinerary_id}/{z}/{x}/{y}",
    pathParameters: ["itinerary_id", "z", "x", "y"],
    queryParameters: ["revision", "surface"],
    mediaTypes: ["application/x-protobuf"]
  )

  /// Retrieve a tile of a map overlay.
  ///
  /// Returns a tile (raster or vector) for a map overlay at the given zoom
  /// level, x, and y coordinates. Overlays include weather layers such as wind
  /// speed and snow depth, terrain analyses such as slope steepness, and points
  /// of interest.
  ///
  /// The weather, snow and points-of-interest overlays return Mapbox Vector Tile
  /// (MVT) binary data and must be used as a `vector` source. The terrain
  /// overlays return raster images, WebP or PNG as the `Content-Type` header
  /// says: hillshade must be used as a `raster-dem` source with a `hillshade`
  /// layer, and slope steepness and aspect/slope as a `raster` source with a
  /// `raster` layer. A tile asked for past its source's `zoom_max` is cut from
  /// the source's tile at that zoom, as a map library overzooms it on its own,
  /// so no `z` from 0 to 22 is refused for its depth: a raster overlay's cut is
  /// always PNG, and a vector overlay's is a vector tile.
  ///
  /// Details for consuming an overlay can be found in [the specification
  /// endpoint](#tag/Overlays/paths/~1v1~1overlays~1{overlay}~1specification/get).
  ///
  /// This route is consumed as a URL template rather than called directly. The
  /// matching specification endpoint returns it under `sources[].tiles` with the
  /// `{z}`, `{x}` and `{y}` placeholders intact, and a map library (MapLibre GL JS,
  /// Mapbox GL JS, or `@mountaya/elements`) expands and fetches them on its own
  /// schedule. The generated SDKs bind no method for it.
  ///
  /// Every overlay starts at zoom 7; the ceiling is what differs, and it is 18
  /// for the weather overlays, 14 for hillshade, and 22 for the terrain analyses
  /// and POIs. Those are the layers' ceilings: the sources of the terrain
  /// analyses stop at 14 and that of the POIs at 15, and a map overzooms their
  /// tiles past it. Read the specification endpoint for the exact `zoom_min` and
  /// `zoom_max` of each layer rather than those figures: they say where a map
  /// should ask for tiles, and a specification served to a publishable key
  /// reports them already narrowed to the organization's zoom-bounds safety
  /// rule. What refuses a `z` is that rule: a publishable-key request for a tile
  /// outside the organization's zoom bounds or geographic boundaries is a
  /// `400`.
  ///
  /// The optional `organization_id` names the studio scope the tile is drawn
  /// for. A map that follows the specification sends the value the
  /// specification was served for, because its URL templates carry it.
  ///
  /// A publishable key needs the `tiles` scope, or `publishing` on a request from
  /// a page on Mountaya's own domain. A share token carries its own authority and
  /// needs none.
  public static let getOverlayTile = URLTemplate(
    operationId: "getOverlayTile",
    path: "/v1/overlays/{overlay}/{z}/{x}/{y}",
    pathParameters: ["overlay", "z", "x", "y"],
    queryParameters: ["organization_id", "timestamp"],
    mediaTypes: ["application/x-protobuf", "image/png", "image/webp"]
  )

  /// Retrieve a range of glyphs for a terrain style's labels.
  ///
  /// Returns the glyphs of one font stack for a block of 256 Unicode code points,
  /// as the protocol-buffer glyph format a map renderer draws text with. It is
  /// the `glyphs` template every terrain style, `getTerrainStyle`, carries, under
  /// the same terrain and rendition as the style, and a renderer expands it with
  /// the font stack and the code-point range each label needs and fetches it on
  /// its own, so the generated SDKs bind no method for it.
  ///
  /// Mountaya fetches it from its base-map provider and answers it with every
  /// address it holds rewritten to point at this API, so a map renderer reaches
  /// the whole base map here, under the credential it sends here, and no answer
  /// carries a credential of Mountaya's.
  ///
  /// A publishable key needs the `tiles` scope, or `publishing` on a request from
  /// a page on Mountaya's own domain, exactly as an overlay tile does. A share
  /// token carries its own authority and needs none. A session token beside the
  /// key changes nothing about what is served: a base map is the same for every
  /// caller.
  ///
  /// Recorded as the organization's Tile API usage under the resource type
  /// `terrain`, on the surface the request comes from, and never counted toward
  /// the organization's per-minute limit or its monthly allowance: a base map is
  /// the frame every other layer is drawn in, and drawing it is Mountaya's cost
  /// rather than the organization's, so a spent monthly allowance never
  /// refuses it either. One bound holds it instead, on every surface and in
  /// place of the surface's others: 6,000 a minute per client IP address, policy
  /// `"address"`, and a request past it is a `429` with `Retry-After`. The
  /// organization's zoom bounds and geographic boundaries do not apply to it.
  public static let getTerrainGlyph = URLTemplate(
    operationId: "getTerrainGlyph",
    path: "/v1/terrains/{terrain}/{variant}/glyphs/{fontstack}/{glyph_range}",
    pathParameters: ["terrain", "variant", "fontstack", "glyph_range"],
    queryParameters: [],
    mediaTypes: ["application/x-protobuf"]
  )

  /// Retrieve a tile of a source a terrain rendition's style draws.
  ///
  /// Returns one tile of one of the sources a terrain rendition's style draws
  /// from, vector or raster, at the given zoom level, x and y coordinates. It is
  /// the `tiles` template every source of `getTerrainStyle` that fetches tiles
  /// carries, under the same terrain and rendition as the style, with the `{z}`,
  /// `{x}` and `{y}` placeholders intact, and a map renderer expands and fetches
  /// it on its own schedule, so the generated SDKs bind no method for it.
  ///
  /// A vector source answers a Mapbox Vector Tile (`application/x-protobuf`), and
  /// a raster one an image, as the `Content-Type` header says. A zero-length
  /// vector tile is a valid empty one, and is the answer for a square inside the
  /// source's range that the source holds nothing on.
  ///
  /// Mountaya fetches it from its base-map provider and answers it with every
  /// address it holds rewritten to point at this API, so a map renderer reaches
  /// the whole base map here, under the credential it sends here, and no answer
  /// carries a credential of Mountaya's.
  ///
  /// A publishable key needs the `tiles` scope, or `publishing` on a request from
  /// a page on Mountaya's own domain, exactly as an overlay tile does. A share
  /// token carries its own authority and needs none. A session token beside the
  /// key changes nothing about what is served: a base map is the same for every
  /// caller.
  ///
  /// Recorded as the organization's Tile API usage under the resource type
  /// `terrain`, on the surface the request comes from, and never counted toward
  /// the organization's per-minute limit or its monthly allowance: a base map is
  /// the frame every other layer is drawn in, and drawing it is Mountaya's cost
  /// rather than the organization's, so a spent monthly allowance never
  /// refuses it either. One bound holds it instead, on every surface and in
  /// place of the surface's others: 6,000 a minute per client IP address, policy
  /// `"address"`, and a request past it is a `429` with `Retry-After`. The
  /// organization's zoom bounds and geographic boundaries do not apply to it.
  public static let getTerrainSourceTile = URLTemplate(
    operationId: "getTerrainSourceTile",
    path: "/v1/terrains/{terrain}/{variant}/sources/{terrain_source}/{z}/{x}/{y}",
    pathParameters: ["terrain", "variant", "terrain_source", "z", "x", "y"],
    queryParameters: [],
    mediaTypes: ["application/x-protobuf", "image/png", "image/jpeg", "image/webp"]
  )

  /// Retrieve a terrain rendition's sprite index or sprite sheet.
  ///
  /// Returns one of the four sprite files of a terrain rendition: `sprite.json`,
  /// the index of the icons the style draws, `sprite.png`, the sheet they are cut
  /// from, and `sprite@2x.json` and `sprite@2x.png`, the same at twice the pixel
  /// density. A map renderer derives all four from the `sprite` address of the
  /// terrain's style, `getTerrainStyle`, and fetches the ones the screen needs on
  /// its own, so the generated SDKs bind no method for it.
  ///
  /// Mountaya fetches it from its base-map provider and answers it with every
  /// address it holds rewritten to point at this API, so a map renderer reaches
  /// the whole base map here, under the credential it sends here, and no answer
  /// carries a credential of Mountaya's.
  ///
  /// A publishable key needs the `tiles` scope, or `publishing` on a request from
  /// a page on Mountaya's own domain, exactly as an overlay tile does. A share
  /// token carries its own authority and needs none. A session token beside the
  /// key changes nothing about what is served: a base map is the same for every
  /// caller.
  ///
  /// Recorded as the organization's Tile API usage under the resource type
  /// `terrain`, on the surface the request comes from, and never counted toward
  /// the organization's per-minute limit or its monthly allowance: a base map is
  /// the frame every other layer is drawn in, and drawing it is Mountaya's cost
  /// rather than the organization's, so a spent monthly allowance never
  /// refuses it either. One bound holds it instead, on every surface and in
  /// place of the surface's others: 6,000 a minute per client IP address, policy
  /// `"address"`, and a request past it is a `429` with `Retry-After`. The
  /// organization's zoom bounds and geographic boundaries do not apply to it.
  public static let getTerrainSprite = URLTemplate(
    operationId: "getTerrainSprite",
    path: "/v1/terrains/{terrain}/{variant}/sprites/{sprite_file}",
    pathParameters: ["terrain", "variant", "sprite_file"],
    queryParameters: [],
    mediaTypes: ["application/json", "image/png"]
  )

  /// Retrieve a terrain rendition as a map style document.
  ///
  /// Returns one rendition of a terrain, light or dark, as a complete map style
  /// document in the MapLibre Style Specification, ready to hand to a map
  /// renderer unmodified. It is the address the layer catalog answers under
  /// `terrains[].variants.<variant>.style.url`, so a client reads it from the
  /// catalog rather than writing it.
  ///
  /// Mountaya fetches it from its base-map provider and answers it with every
  /// address it holds rewritten to point at this API, so a map renderer reaches
  /// the whole base map here, under the credential it sends here, and no answer
  /// carries a credential of Mountaya's. Every source of the style that fetches
  /// tiles carries its `tiles` template on `getTerrainSourceTile` rather than a
  /// `url` of its own, its `sprite` names `getTerrainSprite` and its `glyphs`
  /// names `getTerrainGlyph`, each under the same terrain and rendition as the
  /// style. A source that names no address, such as the provider's
  /// attribution-only source, reaches a client as the provider wrote it.
  ///
  /// The answer is the style document itself, not wrapped in this API's envelope,
  /// because a renderer reads it as it arrives. This route is consumed as an
  /// address handed to a map renderer rather than called directly, so the
  /// generated SDKs bind no method for it.
  ///
  /// A publishable key needs the `tiles` scope, or `publishing` on a request from
  /// a page on Mountaya's own domain, exactly as an overlay tile does. A share
  /// token carries its own authority and needs none. A session token beside the
  /// key changes nothing about what is served: a base map is the same for every
  /// caller.
  ///
  /// Recorded as the organization's Tile API usage under the resource type
  /// `terrain`, on the surface the request comes from, and never counted toward
  /// the organization's per-minute limit or its monthly allowance: a base map is
  /// the frame every other layer is drawn in, and drawing it is Mountaya's cost
  /// rather than the organization's, so a spent monthly allowance never
  /// refuses it either. One bound holds it instead, on every surface and in
  /// place of the surface's others: 6,000 a minute per client IP address, policy
  /// `"address"`, and a request past it is a `429` with `Retry-After`. The
  /// organization's zoom bounds and geographic boundaries do not apply to it.
  public static let getTerrainStyle = URLTemplate(
    operationId: "getTerrainStyle",
    path: "/v1/terrains/{terrain}/{variant}/style",
    pathParameters: ["terrain", "variant"],
    queryParameters: [],
    mediaTypes: ["application/json"]
  )

  /// Retrieve a raster tile of a terrain rendition.
  ///
  /// Returns one raster tile of a terrain rendition at the given zoom level, x
  /// and y coordinates, as an image whose format the `Content-Type` header says.
  /// It is the `tiles` template of the rendition's TileJSON document,
  /// `getTerrainTileJson`, with the `{z}`, `{x}` and `{y}` placeholders intact,
  /// and a map library expands and fetches it on its own schedule, so the
  /// generated SDKs bind no method for it.
  ///
  /// Mountaya fetches it from its base-map provider and answers it with every
  /// address it holds rewritten to point at this API, so a map renderer reaches
  /// the whole base map here, under the credential it sends here, and no answer
  /// carries a credential of Mountaya's.
  ///
  /// A publishable key needs the `tiles` scope, or `publishing` on a request from
  /// a page on Mountaya's own domain, exactly as an overlay tile does. A share
  /// token carries its own authority and needs none. A session token beside the
  /// key changes nothing about what is served: a base map is the same for every
  /// caller.
  ///
  /// Recorded as the organization's Tile API usage under the resource type
  /// `terrain`, on the surface the request comes from, and never counted toward
  /// the organization's per-minute limit or its monthly allowance: a base map is
  /// the frame every other layer is drawn in, and drawing it is Mountaya's cost
  /// rather than the organization's, so a spent monthly allowance never
  /// refuses it either. One bound holds it instead, on every surface and in
  /// place of the surface's others: 6,000 a minute per client IP address, policy
  /// `"address"`, and a request past it is a `429` with `Retry-After`. The
  /// organization's zoom bounds and geographic boundaries do not apply to it.
  public static let getTerrainTile = URLTemplate(
    operationId: "getTerrainTile",
    path: "/v1/terrains/{terrain}/{variant}/{z}/{x}/{y}",
    pathParameters: ["terrain", "variant", "z", "x", "y"],
    queryParameters: [],
    mediaTypes: ["image/png", "image/jpeg", "image/webp"]
  )

  /// Retrieve a terrain rendition as a TileJSON tile source.
  ///
  /// Returns one rendition of a terrain, light or dark, as a raster tile source
  /// described by a TileJSON document, for a client composing a style of its
  /// own rather than drawing the terrain's. It is the address the layer catalog
  /// answers under `terrains[].variants.<variant>.tiles.url`, so a client reads
  /// it from the catalog rather than writing it.
  ///
  /// Mountaya fetches it from its base-map provider and answers it with every
  /// address it holds rewritten to point at this API, so a map renderer reaches
  /// the whole base map here, under the credential it sends here, and no answer
  /// carries a credential of Mountaya's. The document's `tiles` template is
  /// `getTerrainTile`.
  ///
  /// The answer is the TileJSON document itself, not wrapped in this API's
  /// envelope, because a renderer reads it as it arrives. This route is consumed
  /// as an address handed to a map renderer rather than called directly, so the
  /// generated SDKs bind no method for it.
  ///
  /// A publishable key needs the `tiles` scope, or `publishing` on a request from
  /// a page on Mountaya's own domain, exactly as an overlay tile does. A share
  /// token carries its own authority and needs none. A session token beside the
  /// key changes nothing about what is served: a base map is the same for every
  /// caller.
  ///
  /// Recorded as the organization's Tile API usage under the resource type
  /// `terrain`, on the surface the request comes from, and never counted toward
  /// the organization's per-minute limit or its monthly allowance: a base map is
  /// the frame every other layer is drawn in, and drawing it is Mountaya's cost
  /// rather than the organization's, so a spent monthly allowance never
  /// refuses it either. One bound holds it instead, on every surface and in
  /// place of the surface's others: 6,000 a minute per client IP address, policy
  /// `"address"`, and a request past it is a `429` with `Retry-After`. The
  /// organization's zoom bounds and geographic boundaries do not apply to it.
  public static let getTerrainTileJson = URLTemplate(
    operationId: "getTerrainTileJson",
    path: "/v1/terrains/{terrain}/{variant}/tiles.json",
    pathParameters: ["terrain", "variant"],
    queryParameters: [],
    mediaTypes: ["application/json"]
  )

  /// Retrieve a vector tile of the organization's zones.
  ///
  /// Returns a vector tile for zones at the given zoom level, x, and y
  /// coordinates. The response is Mapbox Vector Tile (MVT) binary data. The
  /// zones it draws are the ones `getZones` lists for the same credential: the
  /// organization's public zones as last published under a key alone or with a
  /// session token minted without `user_id`; its public and private zones as
  /// drafts when a session token naming a member accompanies the key, unless
  /// `surface=published` asks for the published snapshots; and none under a
  /// share token, which is answered an empty tile. A collection holding a zone
  /// adds nothing to this aggregate. A collection's zones are drawn by [the
  /// collection tile
  /// endpoint](#/paths/~1v1~1collections~1{collection_id}~1{z}~1{x}~1{y}/get)
  /// with `with_zones=true`, which renders a single collection in isolation, and
  /// only for a credential that could list them. There is no tile of one zone
  /// alone. A publishable-key request for a tile outside the organization's
  /// zoom bounds or geographic boundaries is a `400`.
  ///
  /// The optional `organization_id` names the studio scope the tile is drawn
  /// in. Under a publishable key or a share token it may name only the
  /// credential's own organization and changes nothing. From Mountaya's web
  /// application it chooses which zones are drawn: the person's own, which
  /// belong to no organization, when it is omitted, and the zones of an
  /// organization the person is a member of when it names one, never those of
  /// another space the person belongs to. A map that follows the layer catalog
  /// sends the value the catalog was served for, because the zone layer's URL
  /// template carries it.
  ///
  /// Zone tiles are returned as vector data. They must be used as a `vector`
  /// source. The tile carries one source-layer, `fills`, holding each zone's
  /// polygon. A zone is one feature for each of its polygons. A feature's
  /// geometry is that polygon clipped exactly to a window around the tile,
  /// however intricate it is, from two tiles' width before its square to one
  /// tile's width past it, -8192 to 8191 in the tile's 4,096-unit coordinates,
  /// so it may extend past the tile's square and is not the zone's whole
  /// outline. Draw it clipped to the tile, as a map library does, and take a
  /// zone's outline from the zone itself, never from a tile. A zone stored
  /// before outlines were checked on write is checked by Mountaya shortly
  /// after the release; until it has been, and for good when its outline breaks
  /// a rule a write now holds it to (a valid polygon, at most 10,000 positions,
  /// no meridian or parallel crossing it more than 512 times, which a zone
  /// computed from a source was not held to), it is carried as it is stored and
  /// approximated where it passes through that window many times. The work of one tile is bounded:
  /// a tile whose zones take longer than that to draw is the `504` of a spent
  /// budget.
  ///
  /// A zone drawn from its draft carries its `id`, `name`, `level`, `mode`,
  /// `is_private`, `revision` and `created_by` as properties, and its
  /// `organization_id`, `description`, `start_at` and `end_at` when it has them: a
  /// personal zone, owned by no organization, carries no `organization_id`. A zone
  /// drawn from its publication carries what a published itinerary does: its
  /// `id`, `name`, `level` and `mode`, and its `description`, `start_at` and
  /// `end_at` when the publication has them, never who made it, which
  /// organization holds it, its privacy or its revision. The two bounds are Unix
  /// seconds, so a style can filter on a zone's validity window.
  ///
  /// Details for consuming zones can be found in [the specification
  /// endpoint](#tag/Zones/paths/~1v1~1zones~1specification/get).
  ///
  /// This route is consumed as a URL template rather than called directly. The
  /// matching specification endpoint returns it under `sources[].tiles` with the
  /// `{z}`, `{x}` and `{y}` placeholders intact, and a map library (MapLibre GL JS,
  /// Mapbox GL JS, or `@mountaya/elements`) expands and fetches them on its own
  /// schedule. The generated SDKs bind no method for it.
  ///
  /// A publishable key needs the `tiles` scope, or `publishing` on a request from
  /// a page on Mountaya's own domain. A share token carries its own authority and
  /// needs none.
  public static let getZonesTile = URLTemplate(
    operationId: "getZonesTile",
    path: "/v1/zones/{z}/{x}/{y}",
    pathParameters: ["z", "x", "y"],
    queryParameters: ["surface", "timestamp", "organization_id"],
    mediaTypes: ["application/x-protobuf"]
  )
}
