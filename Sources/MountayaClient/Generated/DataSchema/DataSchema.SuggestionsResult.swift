// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Result of a suggestions query, containing multiple route candidates.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct SuggestionsResult: Sendable, Hashable, Codable {
    /// Suggested route candidates: pinned seeds first, in the order given, then
    /// fresh candidates nearest the target distance first, or nearest the distance
    /// and ascent targets combined when `ascent` is positive. Can hold fewer routes
    /// than `candidates`.
    ///
    /// A candidate crossing a hazard is dropped. For SKI_TOURING,
    /// CROSS_COUNTRY_SKIING and SNOWSHOE_WALKING the hazard check reads the routing
    /// engine's route-level warning, as there is no per-stretch data for those three
    /// (see RouteAdvisories). That warning is raised by any access tag, so a
    /// candidate crossing a PERMISSIVE, AGRICULTURAL or FORESTRY way is dropped as
    /// well.
    ///
    /// When fewer candidates than `candidates` survive because one failed on
    /// Mountaya's side, or a seed `seeds.include` names failed there (whether asked
    /// for once more or not, as `start` states), the field keeps the candidates that
    /// survived and carries an INTERNAL_ERROR entry in `errors` beside them, and the
    /// request is recorded as a failure (5xx), so it counts toward neither the
    /// monthly allowance nor an invoice. An answer holding every candidate asked for
    /// is served whichever extra candidate failed, and a candidate the routing
    /// engine found no routable point or no route for is no such failure.
    public var routes: [DataSchema.SuggestionRoute]?

    /// Creates a `SuggestionsResult` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.routes = nil
      configure(&self)
    }

    /// Reads a `SuggestionsResult` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.routes = try container.decodeIfPresent(
        [DataSchema.SuggestionRoute].self, forKey: "routes")
    }

    /// Writes a `SuggestionsResult` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.routes, forKey: "routes")
    }
  }
}
