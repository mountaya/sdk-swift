// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// GetLayersQuery is the query of `getLayers`, one property to a parameter.
  public struct GetLayersQuery: Sendable, Hashable {
    /// The studio scope the map draws in, named by the organization's identifier. A
    /// value that is not a UUID in its canonical form, or the nil UUID, is a `400`
    /// naming `organization_id`.
    ///
    /// Under a publishable key or a share token it may name only the credential's
    /// own organization: any other identifier is a `403`, whether or not it exists.
    /// It changes nothing but being echoed, so a request sending it is answered as
    /// one that omits it, and every URL template an answer returns under
    /// `sources[].tiles` for a layer that takes it carries the same
    /// `organization_id`.
    ///
    /// A request from Mountaya's web application, which carries the person's own
    /// session rather than a key or a share token, uses it to choose the scope it
    /// draws in. Omitted, the scope is the person's own space, which has no
    /// identifier of its own to send. Naming an organization the person is a member
    /// of makes that organization the scope. Any other identifier, an organization
    /// the person is not a member of or one that does not exist, is a `404`, so the
    /// parameter cannot be used to learn which organizations exist.
    ///
    /// What a scope draws depends on the layer. The overlays served under a key or a
    /// share token are the ones the organization's overlay allowlist admits. From
    /// Mountaya's web application, the person's own space draws the points of
    /// interest alone, and an organization draws every overlay when it holds Map
    /// Studio and the points of interest alone when it does not, an overlay outside
    /// the scope being a `403`. The itinerary and zone tiles draw what the scope
    /// holds: in the person's own space, their own itineraries and zones, which
    /// belong to no organization, and in an organization, its itineraries and zones,
    /// never those of another space the person belongs to.
    public var organization_id: String?

    /// Creates a `GetLayersQuery` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.organization_id = nil
      configure(&self)
    }

    /// items is the query, as the request carries it: one item to a value, in the operation's
    /// order, and none for a parameter left `nil`.
    var items: [QueryItem] {
      var items: [QueryItem] = []
      if let value = self.organization_id {
        items.append(.init(name: "organization_id", value: value))
      }
      return items
    }
  }
}
