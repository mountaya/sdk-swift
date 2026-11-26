// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Input for a forward geocoding query.
  public struct GeocodeInput: Sendable, Hashable, Codable {
    /// User-typed search text. Must be between 1 and 200 characters after trimming
    /// (VALIDATION_FAILED at ["input", "query"] otherwise).
    /// Example: "Chamonix" or "Mont Blanc".
    public var query: String
    /// Language of the returned names. Only EN and FR are localized; any other
    /// language reads English. Defaults to English when omitted.
    public var language: DataSchema.Language?
    /// Maximum number of places to return. Must be between 1 and 50; defaults to 10.
    /// Omitting it returns at most the default rather than everything.
    public var limit: Int?
    /// [longitude, latitude] center used to bias ranking toward nearby results:
    /// exactly two numbers, in range. [0, 0] and an empty list both mean no focus.
    /// Example: [6.8712, 45.9231] to bias results around Chamonix.
    public var focus: [Double]?
    /// [minLongitude, minLatitude, maxLongitude, maxLatitude] bounding box to
    /// restrict the search area: exactly four values, each minimum strictly below its
    /// maximum, and each axis spanning at most 90 degrees. [0, 0, 0, 0] and an empty
    /// list both mean no box.
    public var bbox: [Double]?
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

    /// Creates a `GeocodeInput` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      query: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.query = query
      self.language = nil
      self.limit = nil
      self.focus = nil
      self.bbox = nil
      self.layers = nil
      self.categories = nil
      configure(&self)
    }

    /// Reads a `GeocodeInput` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.query = try container.decode(String.self, forKey: "query")
      self.language = try container.decodeIfPresent(DataSchema.Language.self, forKey: "language")
      self.limit = try container.decodeIfPresent(Int.self, forKey: "limit")
      self.focus = try container.decodeIfPresent([Double].self, forKey: "focus")
      self.bbox = try container.decodeIfPresent([Double].self, forKey: "bbox")
      self.layers = try container.decodeIfPresent([DataSchema.GeocodeLayer].self, forKey: "layers")
      self.categories = try container.decodeIfPresent(
        DataSchema.PlaceCategoriesInput.self, forKey: "categories")
    }

    /// Writes a `GeocodeInput` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.query, forKey: "query")
      try container.encodeIfPresent(self.language, forKey: "language")
      try container.encodeIfPresent(self.limit, forKey: "limit")
      try container.encodeIfPresent(self.focus, forKey: "focus")
      try container.encodeIfPresent(self.bbox, forKey: "bbox")
      try container.encodeIfPresent(self.layers, forKey: "layers")
      try container.encodeIfPresent(self.categories, forKey: "categories")
    }
  }
}
