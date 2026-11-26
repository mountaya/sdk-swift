/// EventStreamRules is what one kind of stream does at its end, on a failure and between two
/// opens, as `sdk/SPEC.md` section 12 states it per stream.
package struct EventStreamRules: Sendable, Hashable {
  /// baseWait is the ceiling of the first wait after an open without progress, which doubles
  /// per consecutive one.
  let baseWait: Duration
  /// maxWait is the ceiling no wait grows past.
  let maxWait: Duration
  /// maxReopens is how many reopens in a row without progress a reader makes before it stops,
  /// or nil where it never stops on its own. An open answered 503 is not one of them where
  /// `maxUnavailable` bounds such opens by time instead.
  let maxReopens: Int?
  /// maxUnavailable is how long the opens answered 503 are held to, from the first of them since
  /// the last progress or `reconnect`, past which the reader stops and reports that 503, or nil
  /// where the reader never stops on them.
  let maxUnavailable: Duration?
  /// framesBeforeProgress is how many frames an open may deliver and still have made no
  /// progress: one on an agent run's stream, which says one thing and hangs up on every try.
  let framesBeforeProgress: Int
  /// endsOnServerError is true where a 5xx other than a 503 or a 504 ends the stream rather
  /// than reopening it.
  let endsOnServerError: Bool
  /// ownArrivalIsProgress is false on an editor stream, whose every open may carry the
  /// `presence.join` of the reader's own member, sent as that member's first stream opens, which
  /// is then no progress; true on every other stream.
  let ownArrivalIsProgress: Bool

  /// agentRun is an agent run's stream: it ends on `done`, its reader stops after six reopens in
  /// a row without progress, since someone is waiting in front of the run, and its opens answered
  /// 503 are held to two minutes instead, since a failover of the store behind the stream can
  /// outlast six reopens.
  static let agentRun = EventStreamRules(
    baseWait: .milliseconds(500),
    maxWait: .seconds(8),
    maxReopens: 6,
    maxUnavailable: .seconds(120),
    framesBeforeProgress: 1,
    endsOnServerError: true,
    ownArrivalIsProgress: true
  )

  /// collaborationFeed is a collaboration feed whose every `presence.join` is progress: an
  /// organization's list stream, or a stream opened by its declaration. It has no end of its own,
  /// and its reader never stops on its own, since nobody is waiting on one answer.
  static let collaborationFeed = EventStreamRules(
    baseWait: .milliseconds(500),
    maxWait: .seconds(15),
    maxReopens: nil,
    maxUnavailable: nil,
    framesBeforeProgress: 0,
    endsOnServerError: false,
    ownArrivalIsProgress: true
  )

  /// collaborationEditor is an itinerary's or a zone's editor stream: a collaboration feed whose
  /// reader's own member's `presence.join` is no progress.
  static let collaborationEditor = EventStreamRules(
    baseWait: .milliseconds(500),
    maxWait: .seconds(15),
    maxReopens: nil,
    maxUnavailable: nil,
    framesBeforeProgress: 0,
    endsOnServerError: false,
    ownArrivalIsProgress: false
  )

  /// lastEventIdHeader is the header a reopen sends the position it resumes from in.
  static let lastEventIdHeader = "Last-Event-ID"

  /// stallWindow is how long an open stream may deliver nothing, not an event and not a
  /// comment, before it is given up: three missed heartbeats of 15 seconds.
  static let stallWindow: Duration = .seconds(45)
}
