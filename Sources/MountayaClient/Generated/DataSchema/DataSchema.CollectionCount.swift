// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Aggregate counts for a collection returned by the collections target. Modelled
  /// as an object (rather than a flat scalar) so a further count can be added without
  /// a breaking change. Mirrors `CollectionCount` on the REST resource field for
  /// field, so one collection reports the same totals through either API.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct CollectionCount: Sendable, Hashable, Codable {
    /// Total number of itineraries contained in the collection.
    public var itineraries: Int?
    /// Total number of zones contained in the collection.
    public var zones: Int?

    /// Creates a `CollectionCount` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.itineraries = nil
      self.zones = nil
      configure(&self)
    }

    /// Reads a `CollectionCount` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.itineraries = try container.decodeIfPresent(Int.self, forKey: "itineraries")
      self.zones = try container.decodeIfPresent(Int.self, forKey: "zones")
    }

    /// Writes a `CollectionCount` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.itineraries, forKey: "itineraries")
      try container.encodeIfPresent(self.zones, forKey: "zones")
    }
  }
}
