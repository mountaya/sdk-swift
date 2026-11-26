// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// A lightweight collection reference returned by the collections target.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct CollectionSearchResult: Sendable, Hashable, Codable {
    /// Collection identifier.
    public var id: String?
    /// Display name of the collection.
    public var name: String?
    /// Free-text description of the collection. Null when it has none.
    public var description: String?
    /// Aggregate counts for the collection.
    public var count: DataSchema.CollectionCount?
    /// Bounding box of the collection's itineraries as [west, south, east, north],
    /// measured as the caller sees them: the same box as the `bbox` of the
    /// collection's tile specification, so one across the antimeridian has west
    /// greater than east. It covers itineraries only, never a zone. Under a session
    /// token minted without `user_id`, the public itineraries as last published, of
    /// owners whose agreement includes Map Publishing; under one naming a member,
    /// the drafts of the itineraries that member reaches. Null when none is drawn
    /// for the caller.
    public var bounds: [Double]?
    /// Whether the collection is private. A private collection is reached only with a
    /// key of the organization that owns it; no other organization's key reaches it,
    /// even with its id. A public one ('anyone with the link') is also readable by id
    /// with any other organization's key, but is never listed in another
    /// organization's search results.
    public var isPrivate: Bool?
    /// Identifier of the organization that owns this collection. Null for a personal
    /// collection, made from an individual account and owned by no organization.
    public var organizationId: String?
    /// Relevance rank over the collection's name and description, always greater than 0,
    /// higher being a better match; a match in the name weighs twice one in the
    /// description. It orders the collections section of ONE response and nothing more.
    /// The value comes from whichever of two ranking passes produced the match: a
    /// full-text rank, which is unbounded above though in practice below 1, or, when
    /// the full-text pass matches nothing and the query is at least two characters
    /// long, a fuzzy similarity between 0.3 and 1. The two scales differ, so a score is
    /// not comparable across responses, across targets, or against a fixed threshold.
    public var score: Double?
    /// Field that produced the match.
    public var matchedField: DataSchema.MatchedField?

    /// Creates a `CollectionSearchResult` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.id = nil
      self.name = nil
      self.description = nil
      self.count = nil
      self.bounds = nil
      self.isPrivate = nil
      self.organizationId = nil
      self.score = nil
      self.matchedField = nil
      configure(&self)
    }

    /// Reads a `CollectionSearchResult` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decodeIfPresent(String.self, forKey: "id")
      self.name = try container.decodeIfPresent(String.self, forKey: "name")
      self.description = try container.decodeIfPresent(String.self, forKey: "description")
      self.count = try container.decodeIfPresent(DataSchema.CollectionCount.self, forKey: "count")
      self.bounds = try container.decodeIfPresent([Double].self, forKey: "bounds")
      self.isPrivate = try container.decodeIfPresent(Bool.self, forKey: "isPrivate")
      self.organizationId = try container.decodeIfPresent(String.self, forKey: "organizationId")
      self.score = try container.decodeIfPresent(Double.self, forKey: "score")
      self.matchedField = try container.decodeIfPresent(
        DataSchema.MatchedField.self, forKey: "matchedField")
    }

    /// Writes a `CollectionSearchResult` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.id, forKey: "id")
      try container.encodeIfPresent(self.name, forKey: "name")
      try container.encodeIfPresent(self.description, forKey: "description")
      try container.encodeIfPresent(self.count, forKey: "count")
      try container.encodeIfPresent(self.bounds, forKey: "bounds")
      try container.encodeIfPresent(self.isPrivate, forKey: "isPrivate")
      try container.encodeIfPresent(self.organizationId, forKey: "organizationId")
      try container.encodeIfPresent(self.score, forKey: "score")
      try container.encodeIfPresent(self.matchedField, forKey: "matchedField")
    }
  }
}
