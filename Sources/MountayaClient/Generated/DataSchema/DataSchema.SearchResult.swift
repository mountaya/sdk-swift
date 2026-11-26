// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Result of the unified search query. Each target's section is non-null only
  /// when that target was enabled and its branch succeeded; failed branches leave
  /// their section null and surface an entry in errors[].
  ///
  /// That includes `query` and `limit`, which each target checks against its own
  /// rules, so a value one target refuses surfaces as its VALIDATION_FAILED entry
  /// instead of failing the request. A request whose every enabled target failed is
  /// answered no result and one error rather than a result holding nothing but its
  /// `errors`: where every target refused the request, the refusal of the first
  /// target in the order the sections are listed (VALIDATION_FAILED at the field it
  /// names, or its own code), and INTERNAL_ERROR as soon as a target failed on
  /// Mountaya's side. Such a request counts toward neither the monthly allowance nor
  /// an invoice. A feature two targets found is returned in one
  /// section only, as `search` states, so a section can hold fewer entries than its
  /// target alone would return.
  ///
  /// The one exception to a failed branch leaving its section null is the ways
  /// target asked to verify (`verifyWays`) whose verification failed on Mountaya's
  /// side for some way: it keeps its section, each activity it could not check kept
  /// as `verifyWays` keeps an unchecked one, and surfaces an INTERNAL_ERROR entry in
  /// errors[] beside it. A request one of whose targets failed on Mountaya's side,
  /// or answered only in part because of a failure on Mountaya's side, keeps every
  /// section that answered and is recorded as a failure (5xx), so it counts toward
  /// neither the monthly allowance nor an invoice.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct SearchResult: Sendable, Hashable, Codable {
    /// Echo of the input query.
    public var query: String?
    /// Language the place, POI and way names were returned in: the requested language
    /// when it is EN or FR, and EN otherwise, including when none was given.
    public var language: DataSchema.Language?
    /// Echo of the per-target enable flags carried by the input.
    public var targets: DataSchema.SearchTargets?
    /// Geocoded places section. Null when the places target was disabled or its
    /// branch errored.
    public var places: DataSchema.GeocodeResult?
    /// Points-of-interest section. Null when the pois target was disabled or its
    /// branch errored.
    public var pois: DataSchema.PoisResult?
    /// Named-ways section. Null when the ways target was disabled or its branch
    /// errored.
    public var ways: DataSchema.WaysResult?
    /// Itineraries section. Null when the itineraries target was disabled or its
    /// branch errored.
    public var itineraries: DataSchema.ItinerariesResult?
    /// Collections section. Null when the collections target was disabled or its
    /// branch errored.
    public var collections: DataSchema.CollectionsResult?
    /// Zones section. Null when the zones target was disabled or its branch
    /// errored.
    public var zones: DataSchema.ZonesResult?
    /// Graceful-degradation entries: one per target whose branch failed, or answered
    /// only in part because of a failure on Mountaya's side. Empty when every enabled
    /// branch succeeded.
    public var errors: [DataSchema.SearchTargetError]?

    /// Creates a `SearchResult` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.query = nil
      self.language = nil
      self.targets = nil
      self.places = nil
      self.pois = nil
      self.ways = nil
      self.itineraries = nil
      self.collections = nil
      self.zones = nil
      self.errors = nil
      configure(&self)
    }

    /// Reads a `SearchResult` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.query = try container.decodeIfPresent(String.self, forKey: "query")
      self.language = try container.decodeIfPresent(DataSchema.Language.self, forKey: "language")
      self.targets = try container.decodeIfPresent(DataSchema.SearchTargets.self, forKey: "targets")
      self.places = try container.decodeIfPresent(DataSchema.GeocodeResult.self, forKey: "places")
      self.pois = try container.decodeIfPresent(DataSchema.PoisResult.self, forKey: "pois")
      self.ways = try container.decodeIfPresent(DataSchema.WaysResult.self, forKey: "ways")
      self.itineraries = try container.decodeIfPresent(
        DataSchema.ItinerariesResult.self, forKey: "itineraries")
      self.collections = try container.decodeIfPresent(
        DataSchema.CollectionsResult.self, forKey: "collections")
      self.zones = try container.decodeIfPresent(DataSchema.ZonesResult.self, forKey: "zones")
      self.errors = try container.decodeIfPresent(
        [DataSchema.SearchTargetError].self, forKey: "errors")
    }

    /// Writes a `SearchResult` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.query, forKey: "query")
      try container.encodeIfPresent(self.language, forKey: "language")
      try container.encodeIfPresent(self.targets, forKey: "targets")
      try container.encodeIfPresent(self.places, forKey: "places")
      try container.encodeIfPresent(self.pois, forKey: "pois")
      try container.encodeIfPresent(self.ways, forKey: "ways")
      try container.encodeIfPresent(self.itineraries, forKey: "itineraries")
      try container.encodeIfPresent(self.collections, forKey: "collections")
      try container.encodeIfPresent(self.zones, forKey: "zones")
      try container.encodeIfPresent(self.errors, forKey: "errors")
    }
  }
}
