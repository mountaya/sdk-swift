// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// A lightweight zone reference returned by the zones target. A zone matches on
  /// its name or its description, and `matchedField` says which.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct ZoneSearchResult: Sendable, Hashable, Codable {
    /// Zone identifier.
    public var id: String?
    /// Display name of the zone.
    public var name: String?
    /// Free-text description of the zone. Null when it has none.
    public var description: String?
    /// How serious the zone is, which is what a renderer picks its styling from. It
    /// carries no access meaning.
    public var level: DataSchema.ZoneLevel?
    /// How the zone's area was drawn or computed. A zone computed from a source is
    /// POLYGON.
    public var mode: DataSchema.ZoneMode?
    /// Representative coordinate as [longitude, latitude]; null when not available.
    public var point: [Double]?
    /// Zone bounding box as [minLongitude, minLatitude, maxLongitude, maxLatitude];
    /// null when not available.
    public var bounds: [Double]?
    /// Whether the zone is private. A private zone is served only to a key of the
    /// organization that owns it; no other organization's key reaches it, even with
    /// its id. A public one is also served by id to any other organization's key, as
    /// last published, but is never listed in another organization's search results.
    public var isPrivate: Bool?
    /// Identifier of the organization that owns this zone. Null for a personal zone,
    /// made from an individual account and owned by no organization.
    public var organizationId: String?
    /// Relevance rank over the zone's name and description, always greater than 0,
    /// higher being a better match; a match in the name weighs twice one in the
    /// description. It orders the zones section of ONE response and nothing more. The
    /// value comes from whichever of two ranking passes produced the match: a
    /// full-text rank, which is unbounded above though in practice below 1, or, when
    /// the full-text pass matches nothing and the query is at least two characters
    /// long, a fuzzy similarity between 0.3 and 1. The two scales differ, so a score is
    /// not comparable across responses, across targets, or against a fixed threshold.
    public var score: Double?
    /// Field that produced the match.
    public var matchedField: DataSchema.MatchedField?

    /// Creates a `ZoneSearchResult` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.id = nil
      self.name = nil
      self.description = nil
      self.level = nil
      self.mode = nil
      self.point = nil
      self.bounds = nil
      self.isPrivate = nil
      self.organizationId = nil
      self.score = nil
      self.matchedField = nil
      configure(&self)
    }

    /// Reads a `ZoneSearchResult` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decodeIfPresent(String.self, forKey: "id")
      self.name = try container.decodeIfPresent(String.self, forKey: "name")
      self.description = try container.decodeIfPresent(String.self, forKey: "description")
      self.level = try container.decodeIfPresent(DataSchema.ZoneLevel.self, forKey: "level")
      self.mode = try container.decodeIfPresent(DataSchema.ZoneMode.self, forKey: "mode")
      self.point = try container.decodeIfPresent([Double].self, forKey: "point")
      self.bounds = try container.decodeIfPresent([Double].self, forKey: "bounds")
      self.isPrivate = try container.decodeIfPresent(Bool.self, forKey: "isPrivate")
      self.organizationId = try container.decodeIfPresent(String.self, forKey: "organizationId")
      self.score = try container.decodeIfPresent(Double.self, forKey: "score")
      self.matchedField = try container.decodeIfPresent(
        DataSchema.MatchedField.self, forKey: "matchedField")
    }

    /// Writes a `ZoneSearchResult` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.id, forKey: "id")
      try container.encodeIfPresent(self.name, forKey: "name")
      try container.encodeIfPresent(self.description, forKey: "description")
      try container.encodeIfPresent(self.level, forKey: "level")
      try container.encodeIfPresent(self.mode, forKey: "mode")
      try container.encodeIfPresent(self.point, forKey: "point")
      try container.encodeIfPresent(self.bounds, forKey: "bounds")
      try container.encodeIfPresent(self.isPrivate, forKey: "isPrivate")
      try container.encodeIfPresent(self.organizationId, forKey: "organizationId")
      try container.encodeIfPresent(self.score, forKey: "score")
      try container.encodeIfPresent(self.matchedField, forKey: "matchedField")
    }
  }
}
