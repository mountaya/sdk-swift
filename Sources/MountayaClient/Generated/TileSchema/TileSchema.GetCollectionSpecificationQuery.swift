// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension TileSchema {
  /// GetCollectionSpecificationQuery is the query of `getCollectionSpecification`, one property to
  /// a parameter.
  public struct GetCollectionSpecificationQuery: Sendable, Hashable {
    /// Reads the published snapshot rather than the draft. `published` is the only
    /// accepted value: there is deliberately no `draft` spelling, because the param
    /// only ever narrows what the caller is served. An unrecognized value is rejected
    /// with a validation error rather than silently ignored. A read of one itinerary,
    /// or of one zone, refuses it with `403` when it is personal, owned by no
    /// organization, to the person whose it is: the published surface is what a
    /// video and an embed are made of, and a personal itinerary or zone makes
    /// neither. Every other caller reads a personal itinerary or zone as published,
    /// and since one is never published it is answered as one that does not exist.
    public var surface: TileSchema.ReadSurface?
    /// Whether the collection's zones are part of the answer. On this route that
    /// is the zone layers the specification declares.
    ///
    /// It declares no `default`, and that is deliberate rather than an omission:
    /// the value when the parameter is absent is the organization's own default for
    /// this layer, clamped to its safety rules for a publishable-key caller, so
    /// there is no one figure this document could publish. For a request from
    /// Mountaya's web application, which names no organization of its own, that
    /// organization is Mountaya's own, and its default is not clamped. Sending it
    /// explicitly is the way to decide it per request, within the rule: on a
    /// publishable-key request an explicit `true` is still capped by the
    /// organization's safety rule.
    public var with_zones: Bool?
    /// Whether the collection's itineraries are part of the answer. On this route
    /// that is the itinerary layers the specification declares, `itinerary_lines`
    /// and `itinerary_points`.
    ///
    /// It declares no `default`, and that is deliberate rather than an omission:
    /// the value when the parameter is absent is the organization's own default for
    /// this layer, clamped to its safety rules for a publishable-key caller, so
    /// there is no one figure this document could publish. For a request from
    /// Mountaya's web application, which names no organization of its own, that
    /// organization is Mountaya's own, and its default is not clamped. Sending it
    /// explicitly is the way to decide it per request, within the rule: on a
    /// publishable-key request an explicit `true` is still capped by the
    /// organization's safety rule.
    public var with_itineraries: Bool?

    /// Creates a `GetCollectionSpecificationQuery` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.surface = nil
      self.with_zones = nil
      self.with_itineraries = nil
      configure(&self)
    }

    /// items is the query, as the request carries it: one item to a value, in the operation's
    /// order, and none for a parameter left `nil`.
    var items: [QueryItem] {
      var items: [QueryItem] = []
      if let value = self.surface {
        items.append(.init(name: "surface", value: value.rawValue))
      }
      if let value = self.with_zones {
        items.append(.init(name: "with_zones", value: String(value)))
      }
      if let value = self.with_itineraries {
        items.append(.init(name: "with_itineraries", value: String(value)))
      }
      return items
    }
  }
}
