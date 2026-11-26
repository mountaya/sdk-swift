// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// GetOrganizationUsageTilesQuery is the query of `getOrganizationUsageTiles`, one property to a
  /// parameter.
  public struct GetOrganizationUsageTilesQuery: Sendable, Hashable {
    /// First day to report, inclusive, as a UTC calendar day. Omitted together with
    /// `end_at`, the range is the current month plus the three complete months before
    /// it. Sent alone, the range runs from it to the end of the current month, or to
    /// the day 365 days after it when that comes first. Sent alone, a `start_at`
    /// after the last day of the current month opens no range and is a `400` with
    /// one entry, at `start_at`. A range is at most 366 calendar days, both ends
    /// included, so `end_at` is at most 365 days after `start_at`. A `start_at`
    /// after `end_at` is a `400`, and so is a wider range, with one entry at
    /// `start_at` and one at `end_at`.
    public var start_at: String?
    /// Last day to report, inclusive, as a UTC calendar day. Sent alone, the range
    /// starts on the day 365 days before it, so it spans 366 calendar days, the
    /// most a range may. A wider range, an `end_at` more than 365 days after
    /// `start_at`, is a `400` with one entry at `start_at` and one at `end_at`.
    public var end_at: String?
    /// Report only the usage that arrived on one publishable key, named by its `pk_`
    /// value. It is spelled `used_publishable_key` rather than `publishable_key`
    /// because the shorter name is how a credential is presented on a query string,
    /// and a filter that collided with it would change who the request is
    /// authenticated as. The `studio-online` and `share` figures are drawn by pages
    /// of Mountaya's web application, under a key of its own rather than one of the
    /// organization's, so a filter on one of the organization's keys leaves them
    /// out.
    public var used_publishable_key: String?
    /// Report only one kind of resource. The values follow the tile ROUTES
    /// rather than the resources themselves, which is why `itinerary` and
    /// `itineraries` are both here: the first counts one itinerary's own tiles
    /// and the second the aggregate layer covering every itinerary the caller
    /// reaches. A request refused, or failed, before any tile route ran, on the
    /// products the organization's agreement grants, the key's scope or the
    /// rate limit, is recorded under the resource its address names, so each
    /// kind reports its refusals beside its traffic; one for the base map under
    /// `terrain`. A request that names no resource, an address no route serves,
    /// an identifier that does not parse, or an overlay or a terrain the catalog
    /// does not list, is counted nowhere. No Tile API request asks for a
    /// payment method, so none is refused for one. A request refused for its
    /// key, its session token or its calling page is counted nowhere.
    ///
    /// It combines with `resource_id` rather than constraining it. The two are
    /// independent filters, so a pair that names a resource of the other kind is
    /// not a 400: it is a report with nothing in it.
    public var resource_type: AdminSchema.UsageTileResourceType?
    /// Report only one resource, by its identifier. A `terrain` figure is
    /// recorded under the `id` the layer catalog gives the terrain its address
    /// names, or the elevation raster's own `id`.
    public var resource_id: String?

    /// Creates a `GetOrganizationUsageTilesQuery` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.start_at = nil
      self.end_at = nil
      self.used_publishable_key = nil
      self.resource_type = nil
      self.resource_id = nil
      configure(&self)
    }

    /// items is the query, as the request carries it: one item to a value, in the operation's
    /// order, and none for a parameter left `nil`.
    var items: [QueryItem] {
      var items: [QueryItem] = []
      if let value = self.start_at {
        items.append(.init(name: "start_at", value: value))
      }
      if let value = self.end_at {
        items.append(.init(name: "end_at", value: value))
      }
      if let value = self.used_publishable_key {
        items.append(.init(name: "used_publishable_key", value: value))
      }
      if let value = self.resource_type {
        items.append(.init(name: "resource_type", value: value.rawValue))
      }
      if let value = self.resource_id {
        items.append(.init(name: "resource_id", value: value))
      }
      return items
    }
  }
}
