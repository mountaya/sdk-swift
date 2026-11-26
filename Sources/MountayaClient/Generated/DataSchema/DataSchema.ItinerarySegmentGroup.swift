// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// A named, colored grouping over a contiguous run of an itinerary's segments, so
  /// several physically-separate segments read as one logical leg ("Day 1", "Stage 3").
  ///
  /// A group is presentation only. Its members are unchanged by grouping: each keeps its
  /// own geometry, metrics, and position. The group overrides only the name, color, and
  /// (when set) the speed shown for that run. Membership is carried on each member
  /// segment's `groupId` rather than nested here.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct ItinerarySegmentGroup: Sendable, Hashable, Codable {
    /// Group identifier.
    public var id: String?
    /// Display name of the group. Example: "Day 1".
    public var name: String?
    /// Hex color code used to paint the whole run as one band. Always set, because a
    /// group with no color would be indistinguishable from no group at all.
    public var color: String?
    /// Travel speed in km/h applied to the whole run when computing the displayed
    /// duration; null means no override, so each member keeps its own speed and the run's
    /// duration is the sum of its members'.
    public var speed: Double?

    /// Creates a `ItinerarySegmentGroup` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.id = nil
      self.name = nil
      self.color = nil
      self.speed = nil
      configure(&self)
    }

    /// Reads a `ItinerarySegmentGroup` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decodeIfPresent(String.self, forKey: "id")
      self.name = try container.decodeIfPresent(String.self, forKey: "name")
      self.color = try container.decodeIfPresent(String.self, forKey: "color")
      self.speed = try container.decodeIfPresent(Double.self, forKey: "speed")
    }

    /// Writes a `ItinerarySegmentGroup` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.id, forKey: "id")
      try container.encodeIfPresent(self.name, forKey: "name")
      try container.encodeIfPresent(self.color, forKey: "color")
      try container.encodeIfPresent(self.speed, forKey: "speed")
    }
  }
}
