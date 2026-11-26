/// EventFrame is one frame of an event stream: the event it carries, and the id a caller
/// resumes from.
public struct EventFrame<Event: Sendable>: Sendable {
  /// id is the frame's stream id, which a caller passes back as `Last-Event-ID` to resume after
  /// it, or nil where the server sent none.
  public let id: String?
  /// event is what the frame carries.
  public let event: Event

  /// Creates a frame, such as a test's stand-in for one the API sent.
  public init(id: String?, event: Event) {
    self.id = id
    self.event = event
  }
}

extension EventFrame: Equatable where Event: Equatable {}

extension EventFrame: Hashable where Event: Hashable {}
