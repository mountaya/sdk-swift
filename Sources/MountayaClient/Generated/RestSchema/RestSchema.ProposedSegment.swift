// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// One proposed segment of an import preview: a single source sub-track rendered
  /// as up to two candidates (directions and/or linestring) with a server
  /// recommendation the user can accept or override. `directions` is absent when
  /// the activity cannot route or routing failed; `linestring` is always present.
  public struct ProposedSegment: Sendable, Hashable, Codable {
    /// Mode the server suggests defaulting to. Reuses the segment mode enum
    /// rather than introducing a separate recommendation type.
    public var recommendation: RestSchema.SegmentMode
    /// Why `linestring` is recommended over `directions`. Null when `directions`
    /// is recommended.
    public var recommendation_reason: RestSchema.ImportRecommendationReason?
    /// Routed candidate. Absent when the activity cannot route or the route could
    /// not be computed faithfully.
    public var directions: RestSchema.ProposedCandidate?
    /// Faithful freehand-line candidate. Always present.
    public var linestring: RestSchema.ProposedCandidate
    /// Proposed segment name: always `Segment #<n>`, numbered from 1 in chain
    /// order, which is the name the studio gives a new segment. A source's own
    /// track names are not carried over. Sent back unchanged, it is accepted by
    /// the import confirm step.
    public var name: String
    /// Hex color code for rendering this segment on the map. Always the empty
    /// string: a preview carries no color over from the source. The import
    /// confirm step refuses an empty `color`, so leave it out there, which gives
    /// the segment the default activity color, or send one the reviewer chose.
    public var color: String
    /// Best-effort travel speed in km/h derived from the source file's per-point
    /// timing (moving speed, excluding dwell). At least 0.01 and at most 999.99
    /// when present, the bounds the import confirm step accepts, so it can be
    /// sent back unchanged. Null when the source carries no timestamps or they
    /// describe a speed outside those bounds, in which case the segment falls
    /// back to the activity default.
    public var speed: Double?

    /// Creates a `ProposedSegment` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      recommendation: RestSchema.SegmentMode,
      recommendation_reason: RestSchema.ImportRecommendationReason?,
      linestring: RestSchema.ProposedCandidate,
      name: String,
      color: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.recommendation = recommendation
      self.recommendation_reason = recommendation_reason
      self.directions = nil
      self.linestring = linestring
      self.name = name
      self.color = color
      self.speed = nil
      configure(&self)
    }

    /// Reads a `ProposedSegment` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.recommendation = try container.decode(
        RestSchema.SegmentMode.self, forKey: "recommendation")
      self.recommendation_reason = try container.decodeIfPresent(
        RestSchema.ImportRecommendationReason.self, forKey: "recommendation_reason")
      self.directions = try container.decodeIfPresent(
        RestSchema.ProposedCandidate.self, forKey: "directions")
      self.linestring = try container.decode(
        RestSchema.ProposedCandidate.self, forKey: "linestring")
      self.name = try container.decode(String.self, forKey: "name")
      self.color = try container.decode(String.self, forKey: "color")
      self.speed = try container.decodeIfPresent(Double.self, forKey: "speed")
    }

    /// Writes a `ProposedSegment` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.recommendation, forKey: "recommendation")
      try container.encodeNullable(self.recommendation_reason, forKey: "recommendation_reason")
      try container.encodeIfPresent(self.directions, forKey: "directions")
      try container.encode(self.linestring, forKey: "linestring")
      try container.encode(self.name, forKey: "name")
      try container.encode(self.color, forKey: "color")
      try container.encodeIfPresent(self.speed, forKey: "speed")
    }
  }
}
