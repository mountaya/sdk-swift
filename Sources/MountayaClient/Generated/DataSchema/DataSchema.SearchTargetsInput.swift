// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Per-target enable flags for the unified search query.
  public struct SearchTargetsInput: Sendable, Hashable, Codable {
    /// Enable the geocoded places target.
    public var places: Bool?
    /// Enable the points-of-interest target.
    public var pois: Bool?
    /// Enable the named-ways target.
    public var ways: Bool?
    /// Enable the itineraries target.
    public var itineraries: Bool?
    /// Enable the collections target.
    public var collections: Bool?
    /// Enable the zones target.
    public var zones: Bool?

    /// Creates a `SearchTargetsInput` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.places = nil
      self.pois = nil
      self.ways = nil
      self.itineraries = nil
      self.collections = nil
      self.zones = nil
      configure(&self)
    }

    /// Reads a `SearchTargetsInput` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.places = try container.decodeIfPresent(Bool.self, forKey: "places")
      self.pois = try container.decodeIfPresent(Bool.self, forKey: "pois")
      self.ways = try container.decodeIfPresent(Bool.self, forKey: "ways")
      self.itineraries = try container.decodeIfPresent(Bool.self, forKey: "itineraries")
      self.collections = try container.decodeIfPresent(Bool.self, forKey: "collections")
      self.zones = try container.decodeIfPresent(Bool.self, forKey: "zones")
    }

    /// Writes a `SearchTargetsInput` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.places, forKey: "places")
      try container.encodeIfPresent(self.pois, forKey: "pois")
      try container.encodeIfPresent(self.ways, forKey: "ways")
      try container.encodeIfPresent(self.itineraries, forKey: "itineraries")
      try container.encodeIfPresent(self.collections, forKey: "collections")
      try container.encodeIfPresent(self.zones, forKey: "zones")
    }
  }
}
