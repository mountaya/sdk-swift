/// AgentRunStream is the reading of an agent run's event stream.
///
/// It ends on `done`, and only on `done`, which carries how the run ended: an `error` or a
/// `budget-exhausted` is published immediately before it and is handed on and read past, and
/// `awaiting-input` ends a turn and not the run, each of the three an ordinary event of the reader.
/// Every event moves the position a reopen resumes from, and an event this build does not know is
/// passed over.
///
/// Every member of the union is an ordinary event unless `sdk/SPEC.md` §12 names its part, so a
/// member a later tag adds, which this build prints, is handed on and moves the position as any
/// event does, and no build waits on a part written for it by hand.
enum AgentRunStream {
  /// role returns the part an event plays, or nil for one this build does not know.
  static func role(of event: RestSchema.AgentRunEvent) -> EventRole? {
    switch event {
    case .AgentDoneEvent:
      .end
    case .AgentReconnectEvent:
      .reconnect
    case .unknown:
      nil
    default:
      .ordinary
    }
  }
}

extension RestSchema.AgentRunEvent: StreamedEvent {
  package static var rules: EventStreamRules {
    .agentRun
  }

  package static func read(_ record: EventRecord) -> (event: Self, role: EventRole)? {
    guard let event = decoded(record), let role = AgentRunStream.role(of: event) else {
      return nil
    }
    return (event, role)
  }
}
