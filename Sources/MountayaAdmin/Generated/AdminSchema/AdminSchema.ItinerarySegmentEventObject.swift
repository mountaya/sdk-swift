// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A segment as a webhook event carries it: its identifiers, its name and how it is
  /// drawn. Its geometry and figures are never carried, and neither is its place in the
  /// chain: an insert, a removal at the head, a merge or a split renumbers the segments
  /// after it, which record no event of their own. `getItinerary` reads the whole chain.
  ///
  /// Every string it carries is bounded, and it carries no geometry, no file and no
  /// credential, so a payload stays small whatever the resource holds.
  public struct ItinerarySegmentEventObject: Sendable, Hashable, Codable {
    /// The kind of object this is, always `itinerary.segment`: the family of the event
    /// types that carry it, and what tells the members of `WebhookEventObject` apart.
    ///
    /// It is always `itinerary.segment`, the discriminator value naming this member of its union.
    public var object: String {
      "itinerary.segment"
    }
    /// Identifier of the segment.
    public var id: String
    /// Identifier of the itinerary the segment belongs to.
    public var itinerary_id: String
    /// The segment's name.
    public var name: String
    /// How the segment is drawn once this change was made.
    public var mode: RestSchema.SegmentMode
    /// The itinerary's `version` once this change was made, which every change to its
    /// segments, segment groups and waypoints moves. Of two events about one itinerary,
    /// the one carrying the higher figure is the later state.
    public var itinerary_version: Int64
    /// When the segment was created.
    public var created_at: Date

    /// Creates a `ItinerarySegmentEventObject` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      id: String,
      itinerary_id: String,
      name: String,
      mode: RestSchema.SegmentMode,
      itinerary_version: Int64,
      created_at: Date,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.id = id
      self.itinerary_id = itinerary_id
      self.name = name
      self.mode = mode
      self.itinerary_version = itinerary_version
      self.created_at = created_at
      configure(&self)
    }

    /// Reads a `ItinerarySegmentEventObject` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decode(String.self, forKey: "id")
      self.itinerary_id = try container.decode(String.self, forKey: "itinerary_id")
      self.name = try container.decode(String.self, forKey: "name")
      self.mode = try container.decode(RestSchema.SegmentMode.self, forKey: "mode")
      self.itinerary_version = try container.decode(Int64.self, forKey: "itinerary_version")
      self.created_at = try container.decodeWired(Date.self, forKey: "created_at")
    }

    /// Writes a `ItinerarySegmentEventObject` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.object, forKey: "object")
      try container.encode(self.id, forKey: "id")
      try container.encode(self.itinerary_id, forKey: "itinerary_id")
      try container.encode(self.name, forKey: "name")
      try container.encode(self.mode, forKey: "mode")
      try container.encode(self.itinerary_version, forKey: "itinerary_version")
      try container.encodeWired(self.created_at, forKey: "created_at")
    }
  }
}
