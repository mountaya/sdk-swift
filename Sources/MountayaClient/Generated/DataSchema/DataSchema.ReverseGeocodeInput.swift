// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Input for a reverse geocoding query.
  public struct ReverseGeocodeInput: Sendable, Hashable, Codable {
    /// [longitude, latitude] anchor point to reverse-geocode: exactly two numbers, in
    /// range (VALIDATION_FAILED at ["input", "point"] otherwise).
    /// Example: [6.8712, 45.9231] for Chamonix.
    public var point: [Double]
    /// Language of the returned names. Only EN and FR are localized; any other
    /// language reads English. Defaults to English when omitted.
    public var language: DataSchema.Language?
    /// Maximum search radius in meters around the anchor point.
    /// Must be between 1 and 5000.
    public var radiusMeters: Int?
    /// Maximum number of places to return. Must be between 1 and 50; defaults to 1,
    /// since a reverse lookup asks which single place a coordinate falls in.
    public var limit: Int?
    /// Layers to restrict results to, at most 10. When omitted, all layers are
    /// eligible. Like `categories`, it runs on the places the geocoder returned for
    /// `limit`, so it can leave fewer than `limit`, or none, even where more places
    /// of those layers exist: POSTCODE does not narrow the geocoder's own search,
    /// and POI and NATURAL narrow it only to the one set both belong to. Raise
    /// `limit` when a narrow filter leaves too few.
    public var layers: [DataSchema.GeocodeLayer]?
    /// Boolean-per-category filter applied to the geocoded place output. When
    /// omitted, every category is allowed. It runs on the places the geocoder
    /// returned for `limit`, so it can leave fewer than `limit`.
    public var categories: DataSchema.PlaceCategoriesInput?

    /// Creates a `ReverseGeocodeInput` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      point: [Double],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.point = point
      self.language = nil
      self.radiusMeters = nil
      self.limit = nil
      self.layers = nil
      self.categories = nil
      configure(&self)
    }

    /// Reads a `ReverseGeocodeInput` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.point = try container.decode([Double].self, forKey: "point")
      self.language = try container.decodeIfPresent(DataSchema.Language.self, forKey: "language")
      self.radiusMeters = try container.decodeIfPresent(Int.self, forKey: "radiusMeters")
      self.limit = try container.decodeIfPresent(Int.self, forKey: "limit")
      self.layers = try container.decodeIfPresent([DataSchema.GeocodeLayer].self, forKey: "layers")
      self.categories = try container.decodeIfPresent(
        DataSchema.PlaceCategoriesInput.self, forKey: "categories")
    }

    /// Writes a `ReverseGeocodeInput` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.point, forKey: "point")
      try container.encodeIfPresent(self.language, forKey: "language")
      try container.encodeIfPresent(self.radiusMeters, forKey: "radiusMeters")
      try container.encodeIfPresent(self.limit, forKey: "limit")
      try container.encodeIfPresent(self.layers, forKey: "layers")
      try container.encodeIfPresent(self.categories, forKey: "categories")
    }
  }
}
