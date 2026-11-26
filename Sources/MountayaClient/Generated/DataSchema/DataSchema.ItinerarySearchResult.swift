// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// A lightweight itinerary reference returned by the itineraries target.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct ItinerarySearchResult: Sendable, Hashable, Codable {
    /// Itinerary identifier.
    public var id: String?
    /// Display name of the itinerary.
    public var name: String?
    /// Free-text description of the itinerary. Null when it has none.
    public var description: String?
    /// Total distance across all of the itinerary's segments, in meters (the sum of
    /// each segment's current distance); null when no segment contributes a distance
    /// value (e.g. the itinerary has no segments).
    public var distance: Double?
    /// Total elevation gain across all of the itinerary's segments, in meters (the
    /// sum of each segment's current ascent); null when no segment contributes an
    /// ascent value (e.g. the itinerary has no segments).
    public var ascent: Int?
    /// Itinerary activity slug; null when no activity is assigned.
    public var activitySlug: DataSchema.ActivitySlug?
    /// Representative start coordinate as [longitude, latitude]; null when not
    /// available.
    public var start: [Double]?
    /// Itinerary bounding box as [minLongitude, minLatitude, maxLongitude, maxLatitude];
    /// null when not available.
    public var bounds: [Double]?
    /// Whether the itinerary is private. A private itinerary is served only to a key
    /// of the organization that owns it; no other organization's key reaches it, even
    /// with its id. A public one ('anyone with the link') is also served by id to any
    /// other organization's key, as last published, but is never listed in another
    /// organization's search results.
    public var isPrivate: Bool?
    /// Identifier of the organization that owns this itinerary. Null for a personal
    /// itinerary, made from an individual account and owned by no organization.
    public var organizationId: String?
    /// Relevance rank over the itinerary's name and description, always greater than 0,
    /// higher being a better match; a match in the name weighs twice one in the
    /// description. It orders the itineraries section of ONE response and nothing more.
    /// The value comes from whichever of two ranking passes produced the match: a
    /// full-text rank, which is unbounded above though in practice below 1, or, when
    /// the full-text pass matches nothing and the query is at least two characters
    /// long, a fuzzy similarity between 0.3 and 1. The two scales differ, so a score is
    /// not comparable across responses, across targets, or against a fixed threshold.
    public var score: Double?
    /// Field that produced the match.
    public var matchedField: DataSchema.MatchedField?

    /// Creates a `ItinerarySearchResult` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.id = nil
      self.name = nil
      self.description = nil
      self.distance = nil
      self.ascent = nil
      self.activitySlug = nil
      self.start = nil
      self.bounds = nil
      self.isPrivate = nil
      self.organizationId = nil
      self.score = nil
      self.matchedField = nil
      configure(&self)
    }

    /// Reads a `ItinerarySearchResult` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decodeIfPresent(String.self, forKey: "id")
      self.name = try container.decodeIfPresent(String.self, forKey: "name")
      self.description = try container.decodeIfPresent(String.self, forKey: "description")
      self.distance = try container.decodeIfPresent(Double.self, forKey: "distance")
      self.ascent = try container.decodeIfPresent(Int.self, forKey: "ascent")
      self.activitySlug = try container.decodeIfPresent(
        DataSchema.ActivitySlug.self, forKey: "activitySlug")
      self.start = try container.decodeIfPresent([Double].self, forKey: "start")
      self.bounds = try container.decodeIfPresent([Double].self, forKey: "bounds")
      self.isPrivate = try container.decodeIfPresent(Bool.self, forKey: "isPrivate")
      self.organizationId = try container.decodeIfPresent(String.self, forKey: "organizationId")
      self.score = try container.decodeIfPresent(Double.self, forKey: "score")
      self.matchedField = try container.decodeIfPresent(
        DataSchema.MatchedField.self, forKey: "matchedField")
    }

    /// Writes a `ItinerarySearchResult` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.id, forKey: "id")
      try container.encodeIfPresent(self.name, forKey: "name")
      try container.encodeIfPresent(self.description, forKey: "description")
      try container.encodeIfPresent(self.distance, forKey: "distance")
      try container.encodeIfPresent(self.ascent, forKey: "ascent")
      try container.encodeIfPresent(self.activitySlug, forKey: "activitySlug")
      try container.encodeIfPresent(self.start, forKey: "start")
      try container.encodeIfPresent(self.bounds, forKey: "bounds")
      try container.encodeIfPresent(self.isPrivate, forKey: "isPrivate")
      try container.encodeIfPresent(self.organizationId, forKey: "organizationId")
      try container.encodeIfPresent(self.score, forKey: "score")
      try container.encodeIfPresent(self.matchedField, forKey: "matchedField")
    }
  }
}
