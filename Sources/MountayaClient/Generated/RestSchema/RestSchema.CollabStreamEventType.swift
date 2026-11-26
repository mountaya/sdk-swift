// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Discriminator for the kind of frame published on a collaboration stream. It is
  /// the `event:` field of each Server-Sent Events record, repeated as the `type`
  /// of the decoded frame so a consumer branches on one value.
  ///
  /// It is one vocabulary across all three collaboration streams. Each stream
  /// carries a subset of it: only an editor stream carries the presence, cursor,
  /// lock and draft frames, only an organization's list stream carries
  /// `collection.changed`, and every stream carries `reconnect`.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct CollabStreamEventType: RawRepresentable, Sendable, Hashable, Codable,
    CodingKeyRepresentable, ExpressibleByStringLiteral
  {
    /// An itinerary was created, updated, or deleted.
    public static let itineraryChanged: Self = "itinerary.changed"
    /// A segment was appended to an itinerary's chain, or updated.
    public static let segmentChanged: Self = "segment.changed"
    /// A waypoint of an itinerary was created, updated, or deleted.
    public static let waypointChanged: Self = "waypoint.changed"
    /// A zone was created, updated, or deleted.
    public static let zoneChanged: Self = "zone.changed"
    /// A collection was created, updated, or deleted, or a resource entered or left one.
    public static let collectionChanged: Self = "collection.changed"
    /// The authoritative set of members present, sent on connect and re-sent periodically.
    public static let presenceSnapshot: Self = "presence.snapshot"
    /// A member opened their first connection to the session.
    public static let presenceJoin: Self = "presence.join"
    /// A member closed their last connection to the session.
    public static let presenceLeave: Self = "presence.leave"
    /// The authoritative set of soft edit locks held, sent on connect and re-sent periodically.
    public static let lockSnapshot: Self = "lock.snapshot"
    /// A member took the soft edit lock on an entity.
    public static let lockAcquired: Self = "lock.acquired"
    /// A member released the soft edit lock on an entity.
    public static let lockReleased: Self = "lock.released"
    /// A member's current selection, or its clear.
    public static let selection: Self = "selection"
    /// A member's cursor position on the map, or its clear.
    public static let cursor: Self = "cursor"
    /// A member's uncommitted draft of an entity they are editing under its lock.
    public static let draftUpdate: Self = "draft.update"
    /// A member's clear of their uncommitted draft for an entity.
    public static let draftClear: Self = "draft.clear"
    /// The credential the stream was opened with ended, so the stream closes; reopen it with a
    /// fresh session token and `Last-Event-ID`.
    public static let reconnect: Self = "reconnect"

    /// rawValue is the value as the wire spells it.
    public let rawValue: String

    /// Creates a value from its wire spelling, which may be one this build has never seen.
    public init(rawValue: String) {
      self.rawValue = rawValue
    }

    /// Creates a value from a string literal, which is its wire spelling.
    public init(stringLiteral value: String) {
      self.rawValue = value
    }

    /// codingKey is the value as an object's key, where the contract keys a map by it.
    public var codingKey: any CodingKey {
      WireKey(stringValue: rawValue)
    }

    /// Creates a value from an object's key.
    public init?<Key: CodingKey>(codingKey: Key) {
      self.rawValue = codingKey.stringValue
    }

    /// Reads the value from its wire spelling.
    public init(from decoder: any Decoder) throws {
      self.rawValue = try decoder.singleValueContainer().decode(String.self)
    }

    /// Writes the value as the wire spells it.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.singleValueContainer()
      try container.encode(rawValue)
    }
  }
}
