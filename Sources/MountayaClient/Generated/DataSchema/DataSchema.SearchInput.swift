// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Input for the unified search query.
  public struct SearchInput: Sendable, Hashable, Codable {
    /// User-typed search text, at most 200 characters after trimming. Every target
    /// except pois also needs at least one character once trimmed; the pois target
    /// accepts an empty query and lists POIs of the requested categories.
    public var query: String
    /// Language of the names the places, pois and ways targets return. Only EN and FR
    /// are localized; any other language reads English. The itineraries, collections
    /// and zones targets ignore it and return names as they were written. Defaults to
    /// English when omitted.
    public var language: DataSchema.Language?
    /// Per-target maximum number of results. Must be between 1 and 50; defaults to 8.
    /// The cap applies to each enabled target independently, so the whole result can
    /// hold up to `limit` × the number of enabled targets, which is why the default is
    /// small. Omitting it caps each target at the default rather than returning
    /// everything. A value outside
    /// the range is refused by every enabled target, each in its own `errors` entry.
    public var limit: Int?
    /// [longitude, latitude] center used to bias ranking toward nearby results for
    /// the places, pois, and ways targets: exactly two numbers, in range, or the
    /// request fails with VALIDATION_FAILED at ["input", "focus"]. [0, 0] and an empty
    /// list both mean no focus.
    public var focus: [Double]?
    /// [minLongitude, minLatitude, maxLongitude, maxLatitude] bounding box used to
    /// restrict the search area for the places, pois, and ways targets. [0, 0, 0, 0]
    /// and an empty list both mean no box; any count other than four fails the
    /// request with VALIDATION_FAILED at ["input", "bbox"]. Each of those three
    /// targets also requires values in range, each minimum strictly below its maximum
    /// and each axis spanning at most 90 degrees, and reports a box that breaks those
    /// rules in `errors`.
    public var bbox: [Double]?
    /// Activity slug used to filter the ways target: a way the activity cannot use is
    /// left out, and the order of the rest is unchanged. Ignored unless
    /// targets.ways = true.
    public var activity: DataSchema.ActivitySlug?
    /// Per-target enable flags. Every field defaults to false; at least one must be
    /// true for the query to execute work. When no flag is true, an empty result is
    /// returned and no usage is recorded, so the request counts toward neither the
    /// monthly allowance nor an invoice, though it still counts toward the
    /// per-minute rate limit.
    public var targets: DataSchema.SearchTargetsInput
    /// Optional POI categories filter applied to the pois target. When omitted,
    /// every category is searched. Ignored unless targets.pois = true.
    public var pois: [DataSchema.POICategory]?
    /// Optional boolean-per-category filter applied to the places target. When
    /// omitted, every category is allowed. Ignored unless targets.places = true.
    public var categories: DataSchema.PlaceCategoriesInput?
    /// Opt-in to routing-graph verification for the ways target. When true, each
    /// candidate way is cross-checked against the same geometry analysis
    /// `analyzeGeometry` performs, and an activity for which that analysis finds a
    /// stretch it cannot classify is dropped from the way's `activityCompatible`. An
    /// activity that could not be checked is kept: a way with no polyline, an
    /// analysis that failed, or an activity with no surface analysis, such as the
    /// winter ones. Materially increases latency; ignored unless targets.ways = true.
    public var verifyWays: Bool?

    /// Creates a `SearchInput` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      query: String,
      targets: DataSchema.SearchTargetsInput,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.query = query
      self.language = nil
      self.limit = nil
      self.focus = nil
      self.bbox = nil
      self.activity = nil
      self.targets = targets
      self.pois = nil
      self.categories = nil
      self.verifyWays = nil
      configure(&self)
    }

    /// Reads a `SearchInput` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.query = try container.decode(String.self, forKey: "query")
      self.language = try container.decodeIfPresent(DataSchema.Language.self, forKey: "language")
      self.limit = try container.decodeIfPresent(Int.self, forKey: "limit")
      self.focus = try container.decodeIfPresent([Double].self, forKey: "focus")
      self.bbox = try container.decodeIfPresent([Double].self, forKey: "bbox")
      self.activity = try container.decodeIfPresent(
        DataSchema.ActivitySlug.self, forKey: "activity")
      self.targets = try container.decode(DataSchema.SearchTargetsInput.self, forKey: "targets")
      self.pois = try container.decodeIfPresent([DataSchema.POICategory].self, forKey: "pois")
      self.categories = try container.decodeIfPresent(
        DataSchema.PlaceCategoriesInput.self, forKey: "categories")
      self.verifyWays = try container.decodeIfPresent(Bool.self, forKey: "verifyWays")
    }

    /// Writes a `SearchInput` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.query, forKey: "query")
      try container.encodeIfPresent(self.language, forKey: "language")
      try container.encodeIfPresent(self.limit, forKey: "limit")
      try container.encodeIfPresent(self.focus, forKey: "focus")
      try container.encodeIfPresent(self.bbox, forKey: "bbox")
      try container.encodeIfPresent(self.activity, forKey: "activity")
      try container.encode(self.targets, forKey: "targets")
      try container.encodeIfPresent(self.pois, forKey: "pois")
      try container.encodeIfPresent(self.categories, forKey: "categories")
      try container.encodeIfPresent(self.verifyWays, forKey: "verifyWays")
    }
  }
}
