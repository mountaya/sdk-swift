// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// One decoded frame off a collaboration stream: the `data:` JSON of a
  /// Server-Sent Events record, with the record's `event:` type folded in as the
  /// `type` discriminator so the frame is self-describing once decoded.
  ///
  /// It is the single source of the vocabulary spoken by all three collaboration
  /// streams: an itinerary's editor stream, a zone's editor stream, and an
  /// organization's list stream. Each carries only a subset of it. Only an editor
  /// stream carries the presence, cursor, lock and draft frames, and only a list
  /// stream carries `collection.changed`. A consumer written against the whole
  /// union reads any of the three, and each operation lists which frames its own
  /// stream can send.
  ///
  /// Two halves behave differently on reconnect. The five change frames are
  /// durable: they carry a stream id and are replayed after `Last-Event-ID`. The
  /// ten presence, selection, cursor, lock and draft frames are live-only: they
  /// carry no id and are never replayed, so a reconnecting client rebuilds that
  /// state from the presence and lock snapshots it is sent on connect. The
  /// `reconnect` frame that ends a stream when its credential ends carries no id
  /// either.
  ///
  /// The event kinds live in CollabStreamEventType, the changed family in
  /// CollabChangeKind, and the mutation in CollabChangeAction, so none of the three
  /// can drift from the others or from prose.
  ///
  /// A member this build has never seen decodes as `unknown`, holding what arrived, so a member the
  /// contract adds decodes in a build made before it. A build made after it reads that member as a
  /// case of its own, so a `switch` over it outside this module ends in `@unknown default`.
  @nonexhaustive
  public enum CollabStreamEvent: Sendable, Hashable, Codable {
    /// `itinerary.changed`.
    case CollabItineraryChangedEvent(RestSchema.CollabItineraryChangedEvent)
    /// `segment.changed`.
    case CollabSegmentChangedEvent(RestSchema.CollabSegmentChangedEvent)
    /// `waypoint.changed`.
    case CollabWaypointChangedEvent(RestSchema.CollabWaypointChangedEvent)
    /// `zone.changed`.
    case CollabZoneChangedEvent(RestSchema.CollabZoneChangedEvent)
    /// `collection.changed`.
    case CollabCollectionChangedEvent(RestSchema.CollabCollectionChangedEvent)
    /// `presence.snapshot`.
    case CollabPresenceSnapshotEvent(RestSchema.CollabPresenceSnapshotEvent)
    /// `presence.join`.
    case CollabPresenceJoinEvent(RestSchema.CollabPresenceJoinEvent)
    /// `presence.leave`.
    case CollabPresenceLeaveEvent(RestSchema.CollabPresenceLeaveEvent)
    /// `lock.snapshot`.
    case CollabLockSnapshotEvent(RestSchema.CollabLockSnapshotEvent)
    /// `lock.acquired`.
    case CollabLockAcquiredEvent(RestSchema.CollabLockAcquiredEvent)
    /// `lock.released`.
    case CollabLockReleasedEvent(RestSchema.CollabLockReleasedEvent)
    /// `selection`.
    case CollabSelectionEvent(RestSchema.CollabSelectionEvent)
    /// `cursor`.
    case CollabCursorEvent(RestSchema.CollabCursorEvent)
    /// `draft.update`.
    case CollabDraftUpdateEvent(RestSchema.CollabDraftUpdateEvent)
    /// `draft.clear`.
    case CollabDraftClearEvent(RestSchema.CollabDraftClearEvent)
    /// `reconnect`.
    case CollabReconnectEvent(RestSchema.CollabReconnectEvent)
    /// unknown is a member this build has never seen, holding what arrived.
    case unknown(JSONValue)

    /// Reads the member its `type` names, or `unknown` for one this build has never seen.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      switch try? container.decode(String.self, forKey: "type") {
      case "itinerary.changed":
        self = .CollabItineraryChangedEvent(
          try RestSchema.CollabItineraryChangedEvent(from: decoder))
      case "segment.changed":
        self = .CollabSegmentChangedEvent(try RestSchema.CollabSegmentChangedEvent(from: decoder))
      case "waypoint.changed":
        self = .CollabWaypointChangedEvent(try RestSchema.CollabWaypointChangedEvent(from: decoder))
      case "zone.changed":
        self = .CollabZoneChangedEvent(try RestSchema.CollabZoneChangedEvent(from: decoder))
      case "collection.changed":
        self = .CollabCollectionChangedEvent(
          try RestSchema.CollabCollectionChangedEvent(from: decoder))
      case "presence.snapshot":
        self = .CollabPresenceSnapshotEvent(
          try RestSchema.CollabPresenceSnapshotEvent(from: decoder))
      case "presence.join":
        self = .CollabPresenceJoinEvent(try RestSchema.CollabPresenceJoinEvent(from: decoder))
      case "presence.leave":
        self = .CollabPresenceLeaveEvent(try RestSchema.CollabPresenceLeaveEvent(from: decoder))
      case "lock.snapshot":
        self = .CollabLockSnapshotEvent(try RestSchema.CollabLockSnapshotEvent(from: decoder))
      case "lock.acquired":
        self = .CollabLockAcquiredEvent(try RestSchema.CollabLockAcquiredEvent(from: decoder))
      case "lock.released":
        self = .CollabLockReleasedEvent(try RestSchema.CollabLockReleasedEvent(from: decoder))
      case "selection":
        self = .CollabSelectionEvent(try RestSchema.CollabSelectionEvent(from: decoder))
      case "cursor":
        self = .CollabCursorEvent(try RestSchema.CollabCursorEvent(from: decoder))
      case "draft.update":
        self = .CollabDraftUpdateEvent(try RestSchema.CollabDraftUpdateEvent(from: decoder))
      case "draft.clear":
        self = .CollabDraftClearEvent(try RestSchema.CollabDraftClearEvent(from: decoder))
      case "reconnect":
        self = .CollabReconnectEvent(try RestSchema.CollabReconnectEvent(from: decoder))
      default:
        self = .unknown(try JSONValue(from: decoder))
      }
    }

    /// Writes the member it holds.
    public func encode(to encoder: any Encoder) throws {
      switch self {
      case .CollabItineraryChangedEvent(let member):
        try member.encode(to: encoder)
      case .CollabSegmentChangedEvent(let member):
        try member.encode(to: encoder)
      case .CollabWaypointChangedEvent(let member):
        try member.encode(to: encoder)
      case .CollabZoneChangedEvent(let member):
        try member.encode(to: encoder)
      case .CollabCollectionChangedEvent(let member):
        try member.encode(to: encoder)
      case .CollabPresenceSnapshotEvent(let member):
        try member.encode(to: encoder)
      case .CollabPresenceJoinEvent(let member):
        try member.encode(to: encoder)
      case .CollabPresenceLeaveEvent(let member):
        try member.encode(to: encoder)
      case .CollabLockSnapshotEvent(let member):
        try member.encode(to: encoder)
      case .CollabLockAcquiredEvent(let member):
        try member.encode(to: encoder)
      case .CollabLockReleasedEvent(let member):
        try member.encode(to: encoder)
      case .CollabSelectionEvent(let member):
        try member.encode(to: encoder)
      case .CollabCursorEvent(let member):
        try member.encode(to: encoder)
      case .CollabDraftUpdateEvent(let member):
        try member.encode(to: encoder)
      case .CollabDraftClearEvent(let member):
        try member.encode(to: encoder)
      case .CollabReconnectEvent(let member):
        try member.encode(to: encoder)
      case .unknown(let value):
        try value.encode(to: encoder)
      }
    }
  }
}
