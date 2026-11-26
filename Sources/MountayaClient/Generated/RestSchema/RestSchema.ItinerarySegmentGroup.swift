// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// A named, colored grouping over a contiguous run of an itinerary's segments, so
  /// several physically-separate segments read as one logical leg ("Day 1", "Stage
  /// 3") on the elevation profile and in the segment chooser.
  ///
  /// A group is presentation only. Its members are unchanged by grouping: each
  /// keeps its own geometry, metrics, revision history, and position, and each
  /// stays individually selectable and editable. The group overrides only the name,
  /// color, and (when set) the speed shown for that run. Membership is carried on
  /// each member segment's group_id rather than nested here, because the ordered
  /// segment chain stays the itinerary's primary structure.
  public struct ItinerarySegmentGroup: Sendable, Hashable, Codable {
    /// Hex color code used to paint the whole run as one band. Always the
    /// six-digit lowercase form, whichever form was written. Always set, because
    /// a group with no color would be indistinguishable from no group at all.
    public var color: String
    /// Timestamp of the segment group's creation.
    public var created_at: Date
    /// The user who created the segment group. It is the author rather than the
    /// last editor, and it does not move when another member edits the segment
    /// group.
    public var created_by: RestSchema.RelationToUser
    /// Unique identifier of the group.
    public var id: String
    /// Identifier of the parent itinerary.
    public var itinerary_id: String
    /// Display name of the segment group.
    public var name: String
    /// Revision number of the segment group, incremented on each change. No
    /// request takes it.
    public var revision: Int
    /// Travel speed in km/h applied to the whole run when computing the displayed
    /// duration, stored rounded to two decimal places and at most 999.99. Null
    /// means no override: each member segment keeps using its own speed (or the
    /// default activity speed where it has none), and the run's duration is the
    /// sum of its members'.
    public var speed: Double?

    /// Creates a `ItinerarySegmentGroup` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      color: String,
      created_at: Date,
      created_by: RestSchema.RelationToUser,
      id: String,
      itinerary_id: String,
      name: String,
      revision: Int,
      speed: Double?,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.color = color
      self.created_at = created_at
      self.created_by = created_by
      self.id = id
      self.itinerary_id = itinerary_id
      self.name = name
      self.revision = revision
      self.speed = speed
      configure(&self)
    }

    /// Reads a `ItinerarySegmentGroup` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.color = try container.decode(String.self, forKey: "color")
      self.created_at = try container.decodeWired(Date.self, forKey: "created_at")
      self.created_by = try container.decode(RestSchema.RelationToUser.self, forKey: "created_by")
      self.id = try container.decode(String.self, forKey: "id")
      self.itinerary_id = try container.decode(String.self, forKey: "itinerary_id")
      self.name = try container.decode(String.self, forKey: "name")
      self.revision = try container.decode(Int.self, forKey: "revision")
      self.speed = try container.decodeIfPresent(Double.self, forKey: "speed")
    }

    /// Writes a `ItinerarySegmentGroup` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.color, forKey: "color")
      try container.encodeWired(self.created_at, forKey: "created_at")
      try container.encode(self.created_by, forKey: "created_by")
      try container.encode(self.id, forKey: "id")
      try container.encode(self.itinerary_id, forKey: "itinerary_id")
      try container.encode(self.name, forKey: "name")
      try container.encode(self.revision, forKey: "revision")
      try container.encodeNullable(self.speed, forKey: "speed")
    }
  }
}
