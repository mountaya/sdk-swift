/// CollaborationFeed is the reading of a collaboration feed: an itinerary's or a zone's editor
/// stream, or an organization's list stream.
///
/// A feed has no end of its own. Its change frames are durable, carry a stream id and move the
/// position a reopen resumes from; its presence, selection, cursor, lock and draft frames are
/// live only, and an id on one moves nothing. The roster and lock snapshots every open begins
/// with are no progress, and on an editor stream neither is the `presence.join` of the reader's
/// own member, sent as that member's first stream opens.
///
/// Every member of the union is an ordinary event unless `sdk/SPEC.md` §12 names its part, so a
/// member a later tag adds, which this build prints, is handed on and moves the position as a
/// change frame does, and no build waits on a part written for it by hand.
enum CollaborationFeed {
  /// editorStreams is the operations whose stream is an itinerary's or a zone's editor stream,
  /// by the name the contract gives each. Every other stream of the vocabulary is a list stream,
  /// an organization's, where every `presence.join` is progress, since section 12 sets the
  /// reader's own apart on an editor stream alone.
  static let editorStreams: Set<String> = ["getItineraryEvents", "getZoneEvents"]

  /// role returns the part an event plays, or nil for one this build does not know.
  static func role(of event: RestSchema.CollabStreamEvent) -> EventRole? {
    switch event {
    case .CollabPresenceSnapshotEvent, .CollabLockSnapshotEvent:
      .openingSnapshot
    case .CollabPresenceJoinEvent, .CollabPresenceLeaveEvent, .CollabLockAcquiredEvent,
      .CollabLockReleasedEvent, .CollabSelectionEvent, .CollabCursorEvent,
      .CollabDraftUpdateEvent, .CollabDraftClearEvent:
      .live
    case .CollabReconnectEvent:
      .reconnect
    case .unknown:
      nil
    default:
      .ordinary
    }
  }
}

extension RestSchema.CollabStreamEvent: StreamedEvent {
  package static var rules: EventStreamRules {
    .collaborationFeed
  }

  package static func rules(for operationId: String) -> EventStreamRules {
    CollaborationFeed.editorStreams.contains(operationId) ? .collaborationEditor : rules
  }

  package var arrivingMember: String? {
    guard case .CollabPresenceJoinEvent(let join) = self else { return nil }
    return join.user_id
  }

  package static func read(_ record: EventRecord) -> (event: Self, role: EventRole)? {
    guard let event = decoded(record), let role = CollaborationFeed.role(of: event) else {
      return nil
    }
    return (event, role)
  }
}
