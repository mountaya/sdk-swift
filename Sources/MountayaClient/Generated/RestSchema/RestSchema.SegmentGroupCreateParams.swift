// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Parameters for grouping a contiguous run of an itinerary's segments under one
  /// name and color.
  ///
  /// The segments themselves are not modified: grouping only overrides the name,
  /// color, and speed shown for that run on the elevation profile and in the
  /// segment chooser.
  public struct SegmentGroupCreateParams: Sendable, Hashable, Codable {
    /// Hex color code used to paint the whole run as one band. Required, because
    /// a group with no color is indistinguishable from no group at all. Both the
    /// three-digit and the six-digit forms are accepted, in either case, and
    /// either is stored as six lowercase digits (`#F60` and `#FF6600` both as
    /// `#ff6600`), which is the form every read returns.
    public var color: String
    /// Display name of the segment group, 2 to 30 characters as sent. Leading and
    /// trailing whitespace is then trimmed, and what remains must still be at
    /// least 2 characters. A name is one line: a tab, a line break or a line
    /// separator between two of its characters is a `400`, and one at either end
    /// is trimmed with the whitespace there.
    public var name: String
    /// Identifiers of the segments to group. They must form a contiguous run of
    /// the itinerary's chain (their positions must be consecutive, in any order
    /// within the array) and none may already belong to another group.
    ///
    /// At least two are required: a one-segment group is indistinguishable from
    /// setting that segment's own name and color. The upper bound is the one
    /// every identifier array on this surface carries.
    ///
    /// A repeated identifier is refused rather than collapsed, because a repeat
    /// would make the run read as shorter than it is and let a selection that is
    /// not contiguous pass the span check.
    public var segment_ids: [String]
    /// Travel speed in km/h applied to the whole run when computing the displayed
    /// duration. At least 0.01 and at most 999.99, and stored rounded to two
    /// decimal places.
    ///
    /// Optional and not nullable: omit it for no override, in which case each
    /// member segment keeps using its own speed. The update operation types the
    /// same field nullable, because there `null` removes an override.
    public var speed: Double?

    /// Creates a `SegmentGroupCreateParams` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      color: String,
      name: String,
      segment_ids: [String],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.color = color
      self.name = name
      self.segment_ids = segment_ids
      self.speed = nil
      configure(&self)
    }

    /// Reads a `SegmentGroupCreateParams` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.color = try container.decode(String.self, forKey: "color")
      self.name = try container.decode(String.self, forKey: "name")
      self.segment_ids = try container.decode([String].self, forKey: "segment_ids")
      self.speed = try container.decodeIfPresent(Double.self, forKey: "speed")
    }

    /// Writes a `SegmentGroupCreateParams` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.color, forKey: "color")
      try container.encode(self.name, forKey: "name")
      try container.encode(self.segment_ids, forKey: "segment_ids")
      try container.encodeIfPresent(self.speed, forKey: "speed")
    }
  }
}
