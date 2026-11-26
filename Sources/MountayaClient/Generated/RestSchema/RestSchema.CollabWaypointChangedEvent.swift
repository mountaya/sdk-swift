// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Stream frame reporting that a waypoint of an itinerary was created, updated,
  /// or deleted. It names what changed, never how, so a consumer refetches the
  /// waypoint or its parent itinerary rather than patching its copy from the frame.
  ///
  /// It reaches only the parent itinerary's editor stream: a waypoint moving is a
  /// concern for whoever has that itinerary open, not for the organization's list.
  public struct CollabWaypointChangedEvent: Sendable, Hashable, Codable {
    /// Always `waypoint.changed` on this frame, and the value of the record's
    /// `event:` field. Branch on it to route the frame; the enum carries every
    /// type the three collaboration streams publish, not only this one.
    ///
    /// It is always `waypoint.changed`, the discriminator value naming this member of its union.
    public var type: RestSchema.CollabStreamEventType {
      "waypoint.changed"
    }
    /// Always `waypoint` on this frame. It restates the family already encoded in
    /// `type`, so a consumer holding only the decoded payload never has to split
    /// the type string to learn what changed.
    public var kind: RestSchema.CollabChangeKind
    /// Which mutation happened to the waypoint. This is the field that varies on
    /// this frame: refetch on a create or an update, drop the local copy on a delete.
    public var action: RestSchema.CollabChangeAction
    /// Identifier of the waypoint that changed.
    public var id: String
    /// Identifier of the itinerary the waypoint belongs to.
    public var itinerary_id: String
    /// Identifier of the organization that owns the itinerary. Always present:
    /// a change to a personal itinerary, made from an individual account and owned
    /// by no organization, is not broadcast, so no event carries one.
    public var organization_id: String
    /// The waypoint's revision after the change, for a consumer holding an older
    /// copy. On a delete it is the revision the waypoint held when it was
    /// removed.
    public var revision: Int
    /// Identifier of the member whose action produced the change.
    public var actor_id: String
    /// When the change occurred, as the server recorded it. A client that
    /// receives events out of order sorts on this rather than on arrival.
    public var occurred_at: Date

    /// Creates a `CollabWaypointChangedEvent` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      kind: RestSchema.CollabChangeKind,
      action: RestSchema.CollabChangeAction,
      id: String,
      itinerary_id: String,
      organization_id: String,
      revision: Int,
      actor_id: String,
      occurred_at: Date,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.kind = kind
      self.action = action
      self.id = id
      self.itinerary_id = itinerary_id
      self.organization_id = organization_id
      self.revision = revision
      self.actor_id = actor_id
      self.occurred_at = occurred_at
      configure(&self)
    }

    /// Reads a `CollabWaypointChangedEvent` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.kind = try container.decode(RestSchema.CollabChangeKind.self, forKey: "kind")
      self.action = try container.decode(RestSchema.CollabChangeAction.self, forKey: "action")
      self.id = try container.decode(String.self, forKey: "id")
      self.itinerary_id = try container.decode(String.self, forKey: "itinerary_id")
      self.organization_id = try container.decode(String.self, forKey: "organization_id")
      self.revision = try container.decode(Int.self, forKey: "revision")
      self.actor_id = try container.decode(String.self, forKey: "actor_id")
      self.occurred_at = try container.decodeWired(Date.self, forKey: "occurred_at")
    }

    /// Writes a `CollabWaypointChangedEvent` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
      try container.encode(self.kind, forKey: "kind")
      try container.encode(self.action, forKey: "action")
      try container.encode(self.id, forKey: "id")
      try container.encode(self.itinerary_id, forKey: "itinerary_id")
      try container.encode(self.organization_id, forKey: "organization_id")
      try container.encode(self.revision, forKey: "revision")
      try container.encode(self.actor_id, forKey: "actor_id")
      try container.encodeWired(self.occurred_at, forKey: "occurred_at")
    }
  }
}
