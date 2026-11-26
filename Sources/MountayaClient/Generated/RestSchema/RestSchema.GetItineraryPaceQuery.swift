// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// GetItineraryPaceQuery is the query of `getItineraryPace`, one property to a parameter.
  public struct GetItineraryPaceQuery: Sendable, Hashable {
    /// Travel speed in km/h on LEVEL ground: the flat pace the travel-time model
    /// starts from, the same quantity `ItinerarySegment.speed` carries and never
    /// the resolved per-stretch speed `speed_info` reports. Required: there is no
    /// default, because the itinerary already has one and a caller who did not
    /// name a pace should read that instead.
    ///
    /// km/h regardless of what the caller displays. Units are a display
    /// preference and the wire carries one unit, so a client showing mph, min/km
    /// or min/mi converts before sending. Outside 0.5 and 100 the value is
    /// REJECTED rather than clamped: a pace nobody walks is a mistake worth
    /// reporting, not one worth guessing at.
    public var speed: Double
    /// Reads the published snapshot rather than the draft. `published` is the only
    /// accepted value: there is deliberately no `draft` spelling, because the param
    /// only ever narrows what the caller is served. An unrecognized value is rejected
    /// with a validation error rather than silently ignored. A read of one itinerary,
    /// or of one zone, refuses it with `403` when it is personal, owned by no
    /// organization, to the person whose it is: the published surface is what a
    /// video and an embed are made of, and a personal itinerary or zone makes
    /// neither. Every other caller reads a personal itinerary or zone as published,
    /// and since one is never published it is answered as one that does not exist.
    public var surface: RestSchema.ReadSurface?

    /// Creates a `GetItineraryPaceQuery` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      speed: Double,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.speed = speed
      self.surface = nil
      configure(&self)
    }

    /// items is the query, as the request carries it: one item to a value, in the operation's
    /// order, and none for a parameter left `nil`.
    var items: [QueryItem] {
      var items: [QueryItem] = []
      items.append(.init(name: "speed", value: String(self.speed)))
      if let value = self.surface {
        items.append(.init(name: "surface", value: value.rawValue))
      }
      return items
    }
  }
}
