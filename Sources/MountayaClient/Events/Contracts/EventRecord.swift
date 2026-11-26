/// EventRecord is one record of a Server-Sent Events stream that carried data: its `event:`
/// name, its `data:` lines joined by a line feed, and its own `id:`.
///
/// It is what a stream opened by an operation's declaration hands on, since the client knows
/// no vocabulary for one this build prints no method for.
public struct EventRecord: Sendable, Hashable {
  /// event is the record's `event:` name, or nil where it names none. A record that names none
  /// is not read as `message`: the API names every record it writes.
  public let event: String?
  /// data is the record's `data:` lines, joined by a line feed.
  public let data: String
  /// id is the record's own `id:`, or nil where it names none: the position a stream resumes
  /// from carries over a record that names none, and the record's own id does not.
  public let id: String?

  /// Creates a record, such as a test's stand-in for one a stream sent.
  public init(event: String?, data: String, id: String?) {
    self.event = event
    self.data = data
    self.id = id
  }
}

/// A stream opened by its declaration is read as a feed: the client knows no event of it, so
/// none ends it and none is passed over, every record's id moves the position, and only the
/// `reconnect` the API writes on every stream is read for what it says.
extension EventRecord: StreamedEvent {
  package static var rules: EventStreamRules {
    .collaborationFeed
  }

  package static func read(_ record: EventRecord) -> (event: EventRecord, role: EventRole)? {
    (record, record.event == "reconnect" ? .reconnect : .ordinary)
  }
}
