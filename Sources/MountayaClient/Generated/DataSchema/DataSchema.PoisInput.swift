// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Input for a points-of-interest query.
  public struct PoisInput: Sendable, Hashable, Codable {
    /// [minLongitude, minLatitude, maxLongitude, maxLatitude] bounding box to
    /// restrict the search area: exactly four values, each minimum strictly below its
    /// maximum, and each axis spanning at most 90 degrees. Mutually exclusive with
    /// buffered: sending both is VALIDATION_FAILED at ["input", "bbox"].
    /// [0, 0, 0, 0] and an empty list both mean no box.
    public var bbox: [Double]?
    /// Polyline or polygon geometry expanded by a buffer in meters. Mutually
    /// exclusive with bbox. POIs are returned only when within the buffer and
    /// annotated with their distance to the geometry.
    ///
    /// A buffered area is asked as the bounding box around it, which the geocoder
    /// ranks and caps at `limit` before the buffer is applied: along a long or
    /// diagonal line, most of that box lies outside the buffer, and the answer can
    /// hold fewer POIs than the area does. Ask for the buffered area in shorter
    /// parts to cover it in full.
    public var buffered: DataSchema.BufferedAreaInput?
    /// POI categories to include. Required. Between 1 and 20 categories.
    public var categories: [DataSchema.POICategory]
    /// Language used to bias the result names. Defaults to English when omitted. Only
    /// EN and FR are localized; any other language reads English.
    public var language: DataSchema.Language?
    /// Maximum number of POIs to return. Must be between 1 and 50; defaults to 50, the
    /// ceiling itself, because a POI sweep of an area is normally wanted whole.
    public var limit: Int?

    /// Creates a `PoisInput` from the properties the contract requires, the optional ones being set
    /// in `configure`.
    public init(
      categories: [DataSchema.POICategory],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.bbox = nil
      self.buffered = nil
      self.categories = categories
      self.language = nil
      self.limit = nil
      configure(&self)
    }

    /// Reads a `PoisInput` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.bbox = try container.decodeIfPresent([Double].self, forKey: "bbox")
      self.buffered = try container.decodeIfPresent(
        DataSchema.BufferedAreaInput.self, forKey: "buffered")
      self.categories = try container.decode([DataSchema.POICategory].self, forKey: "categories")
      self.language = try container.decodeIfPresent(DataSchema.Language.self, forKey: "language")
      self.limit = try container.decodeIfPresent(Int.self, forKey: "limit")
    }

    /// Writes a `PoisInput` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.bbox, forKey: "bbox")
      try container.encodeIfPresent(self.buffered, forKey: "buffered")
      try container.encode(self.categories, forKey: "categories")
      try container.encodeIfPresent(self.language, forKey: "language")
      try container.encodeIfPresent(self.limit, forKey: "limit")
    }
  }
}
