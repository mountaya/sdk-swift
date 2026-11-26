// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Counts of the resources a collection contains. A collection holds itineraries
  /// and zones, and both are counted, so a caller can size a collection without
  /// fetching either listing.
  public struct CollectionCount: Sendable, Hashable, Codable {
    /// Number of itineraries tied to the collection.
    public var itineraries: Int
    /// Number of zones tied to the collection.
    public var zones: Int

    /// Creates a `CollectionCount` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      itineraries: Int,
      zones: Int,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.itineraries = itineraries
      self.zones = zones
      configure(&self)
    }

    /// Reads a `CollectionCount` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.itineraries = try container.decode(Int.self, forKey: "itineraries")
      self.zones = try container.decode(Int.self, forKey: "zones")
    }

    /// Writes a `CollectionCount` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.itineraries, forKey: "itineraries")
      try container.encode(self.zones, forKey: "zones")
    }
  }
}
