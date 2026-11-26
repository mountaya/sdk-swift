// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension Mountaya.Studio {
  /// Layers is every operation of `studio.layers`, one method to an operation.
  public struct Layers: Sendable {
    let sender: any OperationSending

    /// List terrains, overlays, and the zone layer.
    ///
    /// Returns the map layer catalog: the terrain base maps (satellite among them),
    /// the grouped overlay layers (for example slopes), the elevation raster the
    /// terrains are shaded from, and the two layers that draw itineraries and
    /// zones. Which overlay groups it carries follows the studio scope the
    /// optional `organization_id` names. Under a publishable key or a share token
    /// it may name only the credential's own organization and changes nothing,
    /// and the overlays a map draws there are the ones the organization's overlay
    /// allowlist admits, to which the Tile API holds every overlay tile. From
    /// Mountaya's web application it
    /// chooses between the person's own space and an organization they are a
    /// member of, as its description states, and the catalog lists every overlay
    /// in either, the ones the Tile API does not draw in that scope included.
    ///
    /// Reads are limited per minute. A publishable key sent without a session
    /// token, or with one minted without `user_id`, is held to 600 per client IP
    /// address and then 6000 per organization; a key with a session token naming a
    /// user to 1200 per user the token names and then 6000 per organization,
    /// counted apart from the reads made under the key alone; and a share token to
    /// 600 per client IP address and then 6000 per organization that owns the link.
    /// Past any of them the read is a `429` carrying `Retry-After`. A share token
    /// not resolved moments earlier is refused the same way when its client IP
    /// address has had 60 unknown share tokens refused within the minute.
    ///
    /// Requires a publishable key with the `publishing` scope, or the
    /// `studio-embedded` scope that includes it, or a share token: a share view
    /// draws its map from the same catalog an embed does. A map drawn with the
    /// Tile API alone reads the same catalog from the Tile API, `getTileLayers`,
    /// under the `tiles` scope and without Map Publishing; that one lists only the
    /// overlays the organization's overlay allowlist admits.
    public func getLayers(
      query: RestSchema.GetLayersQuery = .init(),
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.Layers, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .getLayers,
        query: query.items
      )
      return try await sender.envelope(request, options: options)
    }
  }
}
