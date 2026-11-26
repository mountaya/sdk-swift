// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Identifiers of the zones to add to a collection. Adding a zone that is already
  /// a member is a no-op rather than a conflict.
  public struct CollectionZonesAddParams: Sendable, Hashable, Codable {
    /// The zones to file into the collection. Every one is resolved and
    /// authorized before any membership is written, so the call succeeds or fails
    /// as a whole. A repeated identifier is collapsed rather than refused, which
    /// is the same answer as naming one that is already a member, and an empty
    /// array is a successful call that changes nothing.
    ///
    /// The bound sits far above any set a person can select in the studio, and
    /// matches the itinerary twin. It exists because each identifier costs an
    /// authorization lookup and a membership write, so an unbounded array is an
    /// unbounded amount of work bought with one request. Over the bound is a
    /// validation error, never a truncation: silently dropping identifiers would
    /// report a collection the caller does not have.
    public var zone_ids: [String]

    /// Creates a `CollectionZonesAddParams` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      zone_ids: [String],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.zone_ids = zone_ids
      configure(&self)
    }

    /// Reads a `CollectionZonesAddParams` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.zone_ids = try container.decode([String].self, forKey: "zone_ids")
    }

    /// Writes a `CollectionZonesAddParams` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.zone_ids, forKey: "zone_ids")
    }
  }
}
