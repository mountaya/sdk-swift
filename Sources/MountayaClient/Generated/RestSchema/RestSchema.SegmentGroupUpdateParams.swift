// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Parameters for updating a segment group. Only provided fields are updated;
  /// omitting segment_ids leaves the group's membership untouched.
  public struct SegmentGroupUpdateParams: Sendable, Hashable, Codable {
    /// Hex color code used to paint the whole run as one band. Both the
    /// three-digit and the six-digit forms are accepted, in either case, and
    /// either is stored as six lowercase digits (`#F60` and `#FF6600` both as
    /// `#ff6600`), which is the form every read returns. Optional and not
    /// nullable: omit it to keep the current color. A group always has one, so
    /// there is nothing for `null` to clear.
    public var color: String?
    /// Display name of the segment group, 2 to 30 characters as sent. Leading and
    /// trailing whitespace is then trimmed, and what remains must still be at
    /// least 2 characters. Optional and not nullable: omit it to keep the current
    /// name. A name is one line: a tab, a line break or a line separator between
    /// two of its characters is a `400`, and one at either end is trimmed with
    /// the whitespace there.
    public var name: String?
    /// The group's new membership, replacing the current one. Optional and not
    /// nullable: omit it to leave the membership untouched. Same rules as on
    /// creation: the segments must form a contiguous run of the itinerary's
    /// chain, none may already belong to another group, and at least two are
    /// required. Segments dropped from the array are un-grouped; to dissolve the
    /// group entirely, delete it instead. The upper bound is the one every
    /// identifier array on this surface carries, and a repeated identifier is
    /// refused rather than collapsed, for the reason creation gives.
    public var segment_ids: [String]?
    /// Travel speed in km/h applied to the whole run when computing the displayed
    /// duration. At least 0.01 and at most 999.99, and stored rounded to two
    /// decimal places. Omit it to keep the current override; `null` removes it,
    /// and each member segment falls back to its own speed.
    ///
    /// Left `nil`, it is not sent, and a value already stored is left as it is. Set to a value, it
    /// is sent, and set to `.some(nil)`, it is sent as `null`, which clears a stored value:
    /// assigning `nil` is the absence of an instruction, never a clear.
    public var speed: Double??

    /// Creates a `SegmentGroupUpdateParams` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.color = nil
      self.name = nil
      self.segment_ids = nil
      self.speed = nil
      configure(&self)
    }

    /// Reads a `SegmentGroupUpdateParams` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.color = try container.decodeIfPresent(String.self, forKey: "color")
      self.name = try container.decodeIfPresent(String.self, forKey: "name")
      self.segment_ids = try container.decodeIfPresent([String].self, forKey: "segment_ids")
      self.speed = try container.decodeMerge(Double.self, forKey: "speed")
    }

    /// Writes a `SegmentGroupUpdateParams` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.color, forKey: "color")
      try container.encodeIfPresent(self.name, forKey: "name")
      try container.encodeIfPresent(self.segment_ids, forKey: "segment_ids")
      try container.encodeMerge(self.speed, forKey: "speed")
    }
  }
}
