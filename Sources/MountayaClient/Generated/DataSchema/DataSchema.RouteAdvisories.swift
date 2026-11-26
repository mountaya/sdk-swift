// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Route-level hazards a client should surface before committing a computed route.
  ///
  /// Each flag is decided by the matching info list when the routing engine returns
  /// per-stretch data for the route, and by the warning the engine attaches to the
  /// route when it does not. A flag can therefore be true while its info list is
  /// empty. On `directions` and `suggestions`, a SKI_TOURING, CROSS_COUNTRY_SKIING or
  /// SNOWSHOE_WALKING route never carries per-stretch data, so its flags always come
  /// from the warning.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct RouteAdvisories: Sendable, Hashable, Codable {
    /// True when the route crosses at least one way that charges a toll for the
    /// activity's mode of travel.
    public var tollway: Bool?
    /// True when the route crosses at least one way carrying a genuine access
    /// restriction. PERMISSIVE grants access rather than restricting it, and
    /// AGRICULTURAL and FORESTRY are ordinary terrain on foot, so none of the three
    /// raises this flag where the routing engine returns per-stretch access data.
    /// Where it returns none, the flag follows the engine's route-level warning,
    /// which any access tag raises, those three included.
    public var restrictedAccess: Bool?
    /// The stretches that cross a tollway, referencing coordinate indices, and only
    /// those. Empty when there are none, or when the engine returned no per-stretch
    /// toll data (read `tollway` then).
    public var tollwayInfo: [DataSchema.TollwayInfo]?
    /// The stretches that carry an access tag, referencing coordinate indices, and
    /// only those. PERMISSIVE, AGRICULTURAL and FORESTRY stretches are listed too, as
    /// information. Empty when there are none, or when the engine returned no
    /// per-stretch access data (read `restrictedAccess` then).
    public var roadAccessInfo: [DataSchema.RoadAccessRestrictionInfo]?

    /// Creates a `RouteAdvisories` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.tollway = nil
      self.restrictedAccess = nil
      self.tollwayInfo = nil
      self.roadAccessInfo = nil
      configure(&self)
    }

    /// Reads a `RouteAdvisories` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.tollway = try container.decodeIfPresent(Bool.self, forKey: "tollway")
      self.restrictedAccess = try container.decodeIfPresent(Bool.self, forKey: "restrictedAccess")
      self.tollwayInfo = try container.decodeIfPresent(
        [DataSchema.TollwayInfo].self, forKey: "tollwayInfo")
      self.roadAccessInfo = try container.decodeIfPresent(
        [DataSchema.RoadAccessRestrictionInfo].self, forKey: "roadAccessInfo")
    }

    /// Writes a `RouteAdvisories` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.tollway, forKey: "tollway")
      try container.encodeIfPresent(self.restrictedAccess, forKey: "restrictedAccess")
      try container.encodeIfPresent(self.tollwayInfo, forKey: "tollwayInfo")
      try container.encodeIfPresent(self.roadAccessInfo, forKey: "roadAccessInfo")
    }
  }
}
