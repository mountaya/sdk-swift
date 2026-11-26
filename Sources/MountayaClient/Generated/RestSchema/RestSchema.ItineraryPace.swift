// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// An itinerary re-timed at one flat pace: the total, and every segment that made
  /// it up. Nothing here is stored. The itinerary's committed speeds are untouched
  /// and the next reader without a pace of their own is served the author's
  /// figures.
  ///
  /// The requested pace REPLACES every per-segment `speed` and every segment
  /// group's `speed` override for the length of this answer. A group override that
  /// survived would produce a run whose duration disagreed with the total below, so
  /// one pace means one pace: the reader asked how long the line takes at their
  /// rate, not at their rate except where the author said otherwise.
  ///
  /// What the pace does not change is the ground. Surfaces, way types and trail
  /// difficulty are properties of the line, not of who walks it, so the model still
  /// slows a climb, speeds a descent and charges for a coarse surface. Only the
  /// flat pace it starts from moved. That is why `speed_info` is the one
  /// info-family member returned and the others are not repeated here.
  ///
  /// Neither is `distance`, nor a segment count: neither moves with a pace, both
  /// are already carried by `ItineraryWithDetails` and its segments, and a second
  /// copy could only disagree with the first.
  public struct ItineraryPace: Sendable, Hashable, Codable {
    /// Total travel duration of the itinerary in seconds at the requested pace.
    /// Equal to the sum of `segments[].duration`, so a client may display either
    /// without the two disagreeing.
    public var duration: Double
    /// One entry per segment of the itinerary, in itinerary order. Every segment
    /// is present, including a segment with no geometry, which answers `0`.
    public var segments: [RestSchema.ItineraryPaceSegment]

    /// Creates a `ItineraryPace` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      duration: Double,
      segments: [RestSchema.ItineraryPaceSegment],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.duration = duration
      self.segments = segments
      configure(&self)
    }

    /// Reads a `ItineraryPace` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.duration = try container.decode(Double.self, forKey: "duration")
      self.segments = try container.decode(
        [RestSchema.ItineraryPaceSegment].self, forKey: "segments")
    }

    /// Writes a `ItineraryPace` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.duration, forKey: "duration")
      try container.encode(self.segments, forKey: "segments")
    }
  }
}
