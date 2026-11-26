// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension Mountaya {
  /// tiles is every operation of the Tile API a caller awaits.
  public var tiles: Tiles {
    Tiles(sender: sender)
  }

  /// Tiles is the Tile API's operations, one method to an operation. The tile routes themselves are
  /// URL templates a map fetches, and no method here binds one.
  public struct Tiles: Sendable {
    let sender: any OperationSending

    /// Retrieve the tile specification for a collection.
    ///
    /// Returns the tile specification (sources and layers) for rendering a
    /// collection on a MapLibre GL map. The response includes tile URLs, layer
    /// configuration, paint properties, and zoom range constraints needed to add
    /// the collection as a vector source.
    ///
    /// Collection tiles carry zone and itinerary layers. Zone layers are painted by
    /// zone level (info, warning, danger, resolved); itinerary layers take their
    /// color per feature, and a feature that carries none falls back to a fixed
    /// default color, the last argument of the `coalesce` in the layer's `paint`.
    ///
    /// The declared layers are narrowed by the resolved `with_zones` and
    /// `with_itineraries` toggles, whatever the credential, and on a
    /// publishable-key request those toggles are clamped to the organization's
    /// safety rules, so the specification never declares a layer the toggles
    /// switch off. They are not narrowed by what the credential may see: the tile
    /// draws only the members this credential could list, so the zone layer
    /// declared to a publishable key without a session token naming a member
    /// draws the collection's published public zones alone, and every layer of
    /// another organization's collection stays empty.
    ///
    /// The answer also carries `bbox`, the extent of the itineraries the tiles
    /// draw for this same credential, the same `surface` and the same
    /// `with_itineraries`, so an embed opens on the whole collection: fit the
    /// map's camera to it once the sources are registered. Zones do not count
    /// toward it, it is not clipped to the organization's geographic boundaries,
    /// and it is null when the tiles draw no itinerary. Ask for the
    /// specification with the `surface` the tiles are asked for with, so the
    /// two agree.
    ///
    /// A publishable key needs the `tiles` scope, or `publishing` on a request from
    /// a page on Mountaya's own domain. A share token carries its own authority and
    /// needs none.
    public func getCollectionSpecification(
      collection_id: String,
      query: TileSchema.GetCollectionSpecificationQuery = .init(),
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<TileSchema.TileSpecification, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .getCollectionSpecification,
        pathParameters: ["collection_id": collection_id],
        query: query.items
      )
      return try await sender.envelope(request, options: options)
    }

    /// Retrieve the tile specification for the organization's itineraries.
    ///
    /// Returns the tile specification (sources and layers) for rendering the
    /// organization's itineraries on a MapLibre GL map. The response includes
    /// tile URLs, layer configuration, paint properties, and zoom range
    /// constraints needed to add itineraries as a vector source.
    ///
    /// Itinerary tiles contain three source layers: `itinerary_lines` for segment
    /// line geometries, `itinerary_points` for point geometries and
    /// `itinerary_restrictions` for the restricted stretches of a segment, which
    /// no layer of this specification draws (see the tile route). The
    /// `itinerary_points` layer carries both true waypoints and the per-itinerary
    /// start and end markers, all rendered by a single symbol layer keyed on
    /// `section-icon-<icon>-<hex>`. Every feature exposes `icon` and `color`, with
    /// `icon = 'flag-start' | 'flag-end'` for endpoint markers. Endpoint marker
    /// features also carry an informational `marker_role` (`start` / `end`) that
    /// is absent on waypoints. The itineraries the tiles draw are the ones
    /// `getItineraries` lists for the same credential: the organization's public
    /// itineraries as last published under a key alone or with a session token
    /// minted without `user_id`; its public and private itineraries as drafts when
    /// a session token naming a member accompanies the key; and none under a share
    /// token.
    ///
    /// A publishable key needs the `tiles` scope, or `publishing` on a request from
    /// a page on Mountaya's own domain. A share token carries its own authority and
    /// needs none.
    public func getItinerariesSpecification(
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<TileSchema.TileSpecification, [String: JSONValue]?> {
      let request = OperationRequest(facts: .getItinerariesSpecification)
      return try await sender.envelope(request, options: options)
    }

    /// Retrieve the tile specification for a single itinerary.
    ///
    /// Returns the tile specification (sources and layers) for rendering a single
    /// itinerary on a MapLibre GL map. The response includes tile URLs, layer
    /// configuration, paint properties, and zoom range constraints needed to add
    /// the itinerary as a vector source.
    ///
    /// Itinerary tiles contain three source layers: `itinerary_lines` for line
    /// geometries, `itinerary_points` for point geometries (waypoints and the
    /// per-itinerary endpoint markers), and `itinerary_restrictions` for the
    /// restricted stretches of a segment, which no layer of this specification
    /// draws (see the tile route).
    ///
    /// A publishable key needs the `tiles` scope, or `publishing` on a request from
    /// a page on Mountaya's own domain. A share token carries its own authority and
    /// needs none.
    public func getItinerarySpecification(
      itinerary_id: String,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<TileSchema.TileSpecification, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .getItinerarySpecification,
        pathParameters: ["itinerary_id": itinerary_id]
      )
      return try await sender.envelope(request, options: options)
    }

    /// Retrieve the tile specification for a map overlay.
    ///
    /// Returns the tile specification (sources and layers) for rendering a map
    /// overlay on a MapLibre GL map. The response includes tile URLs, layer
    /// configuration, paint properties, legend data with units, and zoom range
    /// constraints needed to add the overlay as a source.
    ///
    /// Overlays can be either vector or raster sources depending on the data type.
    /// The specification includes legend information with color scales and unit
    /// labels (e.g., km/h for wind speed, meters for snow depth).
    ///
    /// The optional `organization_id` names the studio scope the overlay is drawn
    /// for, and the URL templates the specification returns carry it on to every
    /// tile.
    ///
    /// A publishable key needs the `tiles` scope, or `publishing` on a request from
    /// a page on Mountaya's own domain. A share token carries its own authority and
    /// needs none.
    public func getOverlaySpecification(
      overlay: String,
      query: TileSchema.GetOverlaySpecificationQuery = .init(),
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<TileSchema.TileSpecification, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .getOverlaySpecification,
        pathParameters: ["overlay": overlay],
        query: query.items
      )
      return try await sender.envelope(request, options: options)
    }

    /// List the terrains, overlays and layers this API draws.
    ///
    /// Returns the map layer catalog this API draws from: the terrain base maps,
    /// the elevation raster the terrains are shaded from, the grouped overlay
    /// layers, and the two layers that draw itineraries and zones. It is the
    /// catalog the Map Studio API's `getLayers` answers at its `/v1/layers`, in the
    /// same shape, served here under the `tiles` scope, so a map drawn with the
    /// Tile API alone finds every layer by its slug without Map Publishing.
    ///
    /// Under a publishable key or a share token, `overlays` lists only the
    /// overlays the organization's overlay allowlist admits, the ones this API
    /// draws for the credential, and a group left with none is dropped: the
    /// allowlist starts empty on a new organization, so the groups are empty until
    /// Mountaya sets it as the organization's agreement states. An overlay listed
    /// here may still be drawn only at the present instant: the organization's
    /// overlay time control decides whether one whose `capabilities.server.timestamp`
    /// is true is drawn more than 15 minutes from the current instant, which this
    /// catalog does not report. The terrains, the elevation raster and the
    /// itinerary and zone layers are listed for every credential.
    ///
    /// The optional `organization_id` names the studio scope the catalog is drawn
    /// for, as on the overlay routes. Under a publishable key or a share token it
    /// may name only the credential's own organization and changes nothing. From
    /// Mountaya's web application it chooses between the person's own space and an
    /// organization they are a member of, and `overlays` lists every overlay in
    /// either, so the studio can show the ones the scope does not draw, locked.
    /// This API draws the points of interest alone in the person's own space and
    /// in an organization that does not hold Map Studio, and every overlay in one
    /// that does, and the itinerary and zone layers draw the scope's own
    /// itineraries and zones. When it is sent, the tile URL template of every
    /// overlay and of the itinerary and zone layers carries it on, so the tiles a
    /// map fetches are drawn in the scope the catalog was served for.
    ///
    /// Like a specification, the catalog is never recorded, and it counts toward
    /// the per-minute bounds "What is counted" lists for its surface.
    ///
    /// A publishable key needs the `tiles` scope, or `publishing` on a request from
    /// a page on Mountaya's own domain. A share token carries its own authority and
    /// needs none.
    public func getTileLayers(
      query: TileSchema.GetTileLayersQuery = .init(),
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<TileSchema.Layers, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .getTileLayers,
        query: query.items
      )
      return try await sender.envelope(request, options: options)
    }

    /// Retrieve the tile specification for the organization's zones.
    ///
    /// Returns the tile specification (sources and layers) for rendering zone
    /// annotations on a MapLibre GL map. The response includes tile URLs, layer
    /// configuration, paint properties, and zoom range constraints needed to add
    /// zones as a vector source.
    ///
    /// Zone tiles carry one source-layer, `fills`, holding each zone's polygon,
    /// color-coded by severity level (info, warning, danger, resolved): one
    /// feature for each of its polygons, clipped exactly to a window from two
    /// tiles' width before the tile's square to one past it, so a feature may
    /// extend past the square and is not the zone's whole outline. A zone stored
    /// before outlines were checked on write is approximated where it passes
    /// through that window many times until Mountaya has checked it, shortly
    /// after the release, and for good when its outline breaks a rule a write now
    /// holds it to: a valid polygon of at most 10,000 positions that no meridian
    /// or parallel crosses more than 512 times.
    ///
    /// A zone drawn from its draft carries its `id`, `name`, `level`, `mode`,
    /// `is_private`, `revision` and `created_by` as properties, and its
    /// `organization_id`, `description`, `start_at` and `end_at` when it has them: a
    /// personal zone, owned by no organization, carries no `organization_id`. A zone
    /// drawn from its publication carries what a published itinerary does: its
    /// `id`, `name`, `level` and `mode`, and its `description`, `start_at` and
    /// `end_at` when the publication has them, never who made it, which
    /// organization holds it, its privacy or its revision. The two bounds are Unix
    /// seconds, so a style can filter on a zone's validity window. The
    /// zones the tiles draw are the ones `getZones` lists for the same
    /// credential: the organization's public zones as last published under a key
    /// alone or with a session token minted without `user_id`; its public and
    /// private zones as drafts when a session token naming a member accompanies
    /// the key; and none under a share token.
    ///
    /// A publishable key needs the `tiles` scope, or `publishing` on a request from
    /// a page on Mountaya's own domain. A share token carries its own authority and
    /// needs none.
    public func getZonesSpecification(
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<TileSchema.TileSpecification, [String: JSONValue]?> {
      let request = OperationRequest(facts: .getZonesSpecification)
      return try await sender.envelope(request, options: options)
    }
  }
}
