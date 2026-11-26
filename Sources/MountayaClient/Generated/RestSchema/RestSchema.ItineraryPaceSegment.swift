// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// One segment of an itinerary, re-timed at a requested flat pace. The segment is
  /// identified by its own `id`, so a client joins this entry to the segment it
  /// already holds rather than trusting array position across two calls.
  ///
  /// `duration` and `speed_info` come out of the same walk over the same geometry,
  /// so the total and the per-stretch speeds can never disagree: summing each
  /// stretch's length divided by its `value` reproduces `duration`, exactly as it
  /// does on `ItinerarySegment`.
  public struct ItineraryPaceSegment: Sendable, Hashable, Codable {
    /// Travel duration of the segment in seconds at the requested pace. Always
    /// present: turning a pace into a duration is this operation's whole job. A
    /// segment with no geometry, or none the model can walk, answers `0` rather
    /// than null, and contributes nothing to the itinerary total.
    public var duration: Double
    /// Identifier of the segment this entry times. It is the stored segment's own
    /// id, unchanged: the re-time computes a duration, it does not create
    /// anything. On a re-time of the published snapshot it is the snapshot's id,
    /// which differs from the draft's and changes at every publish, so join it to
    /// a `getItinerary` read served the same version.
    public var id: String
    /// Resolved travel speed in km/h along the segment geometry at the requested
    /// pace. Each entry references a coordinate index range, the same index basis
    /// the stored segment's `speed_info` uses. Empty for a segment with no
    /// geometry, which is the same case `duration: 0` describes.
    ///
    /// This is the per-stretch speed the duration was integrated over, not the
    /// requested pace: the model still slows a climb, speeds a descent, and
    /// charges for a coarse surface or a technical trail. Only the flat pace it
    /// starts from changed.
    ///
    /// Never null, where the segment's own `speed_info` is. That one is nullable
    /// because the metric may never have been computed for the segment; a re-time
    /// always ran, so "it ran and found no geometry to walk" is a different
    /// answer from "nobody has asked yet" and the two are spelled apart rather
    /// than collapsed onto one absent value.
    public var speed_info: [RestSchema.SpeedInfo]

    /// Creates a `ItineraryPaceSegment` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      duration: Double,
      id: String,
      speed_info: [RestSchema.SpeedInfo],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.duration = duration
      self.id = id
      self.speed_info = speed_info
      configure(&self)
    }

    /// Reads a `ItineraryPaceSegment` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.duration = try container.decode(Double.self, forKey: "duration")
      self.id = try container.decode(String.self, forKey: "id")
      self.speed_info = try container.decode([RestSchema.SpeedInfo].self, forKey: "speed_info")
    }

    /// Writes a `ItineraryPaceSegment` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.duration, forKey: "duration")
      try container.encode(self.id, forKey: "id")
      try container.encode(self.speed_info, forKey: "speed_info")
    }
  }
}
