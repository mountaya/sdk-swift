// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Result of a reverse geocoding query.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct ReverseGeocodeResult: Sendable, Hashable, Codable {
    /// Echo of the anchor [longitude, latitude] point used for the lookup.
    public var point: [Double]?
    /// List of named places, in the order the geocoder returns them for the point.
    public var places: [DataSchema.Place]?
    /// Number of places returned: the length of `places`, at most `limit`.
    public var count: Int?

    /// Creates a `ReverseGeocodeResult` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.point = nil
      self.places = nil
      self.count = nil
      configure(&self)
    }

    /// Reads a `ReverseGeocodeResult` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.point = try container.decodeIfPresent([Double].self, forKey: "point")
      self.places = try container.decodeIfPresent([DataSchema.Place].self, forKey: "places")
      self.count = try container.decodeIfPresent(Int.self, forKey: "count")
    }

    /// Writes a `ReverseGeocodeResult` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.point, forKey: "point")
      try container.encodeIfPresent(self.places, forKey: "places")
      try container.encodeIfPresent(self.count, forKey: "count")
    }
  }
}
