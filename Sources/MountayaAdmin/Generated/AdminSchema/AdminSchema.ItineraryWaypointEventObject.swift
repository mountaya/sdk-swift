// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A waypoint as a webhook event carries it: its identifiers, its name and its mode. Its
  /// location and content are never carried: `getItinerary` reads them.
  ///
  /// Every string it carries is bounded, and it carries no geometry, no file and no
  /// credential, so a payload stays small whatever the resource holds.
  public struct ItineraryWaypointEventObject: Sendable, Hashable, Codable {
    /// The kind of object this is, always `itinerary.waypoint`: the family of the event
    /// types that carry it, and what tells the members of `WebhookEventObject` apart.
    ///
    /// It is always `itinerary.waypoint`, the discriminator value naming this member of its union.
    public var object: String {
      "itinerary.waypoint"
    }
    /// Identifier of the waypoint.
    public var id: String
    /// Identifier of the itinerary the waypoint belongs to.
    public var itinerary_id: String
    /// The waypoint's name, null on one that carries none.
    public var name: String?
    /// What kind of waypoint it is.
    public var mode: RestSchema.WaypointMode
    /// The itinerary's `version` once this change was made, which every change to its
    /// segments, segment groups and waypoints moves. Of two events about one itinerary,
    /// the one carrying the higher figure is the later state.
    public var itinerary_version: Int64
    /// When the waypoint was created.
    public var created_at: Date

    /// Creates a `ItineraryWaypointEventObject` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      id: String,
      itinerary_id: String,
      name: String?,
      mode: RestSchema.WaypointMode,
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

    /// Reads a `ItineraryWaypointEventObject` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decode(String.self, forKey: "id")
      self.itinerary_id = try container.decode(String.self, forKey: "itinerary_id")
      self.name = try container.decodeIfPresent(String.self, forKey: "name")
      self.mode = try container.decode(RestSchema.WaypointMode.self, forKey: "mode")
      self.itinerary_version = try container.decode(Int64.self, forKey: "itinerary_version")
      self.created_at = try container.decodeWired(Date.self, forKey: "created_at")
    }

    /// Writes a `ItineraryWaypointEventObject` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.object, forKey: "object")
      try container.encode(self.id, forKey: "id")
      try container.encode(self.itinerary_id, forKey: "itinerary_id")
      try container.encodeNullable(self.name, forKey: "name")
      try container.encode(self.mode, forKey: "mode")
      try container.encode(self.itinerary_version, forKey: "itinerary_version")
      try container.encodeWired(self.created_at, forKey: "created_at")
    }
  }
}
