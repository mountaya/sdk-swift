/// EventStream is an event stream's frames, in the order the server sent them, read by the
/// rules of `sdk/SPEC.md` section 12 from open to end.
///
/// It is cold: each iteration opens the stream afresh, and nothing is sent until one starts. It
/// reopens the stream itself where those rules do, after the wait they set, resuming from the
/// last record it handed on, and ends where they say it is over: an agent run's on `done`, a
/// collaboration feed only when the iterating task lets it go. Iterating throws a
/// `MountayaError` for a failure that ends the stream, and `CancellationError` once the
/// iterating task is cancelled.
public struct EventStream<Event: Sendable>: AsyncSequence, Sendable {
  /// Element is one frame.
  public typealias Element = EventFrame<Event>

  /// open opens the frames of one iteration, read as the user it is handed, where one is named.
  private let open: @Sendable (_ member: String?) -> any FrameReading<Event>
  /// member is the user the stream is read as, where its caller names one.
  private let member: String?

  /// Creates a stream that opens its frames afresh for each iteration, read as `member`.
  init(
    member: String? = nil,
    open: @escaping @Sendable (_ member: String?) -> any FrameReading<Event>
  ) {
    self.member = member
    self.open = open
  }

  /// Creates a stream over a fixed list of frames, such as a test's stand-in for one the API
  /// sent.
  public init(frames: [EventFrame<Event>]) {
    self.init { _ in FixedFrames(frames) }
  }

  /// makeAsyncIterator opens the stream.
  public func makeAsyncIterator() -> Iterator {
    Iterator(reading: open(member))
  }

  /// Iterator reads one opening of the stream.
  ///
  /// It is not `Sendable`: it is one task's cursor over a reading no other task may share, as
  /// the standard library's `AsyncStream.Iterator` is, and its sequence is what crosses tasks.
  public struct Iterator: AsyncIteratorProtocol {
    let reading: any FrameReading<Event>

    /// next returns the next frame, or nil once the stream is over.
    public mutating func next() async throws -> EventFrame<Event>? {
      try await reading.next()
    }
  }
}

extension EventStream where Event == RestSchema.CollabStreamEvent {
  /// reading returns the stream read as the user `userId`, which an editor stream's reader needs
  /// where the session token does not tell the client whom it names, a token given as a value or
  /// a function: that user's own `presence.join`, sent as its first stream opens, is then no
  /// progress, and an open that delivers nothing else waits before the next. A user the session
  /// token names is read first, and an organization's list stream reads every `presence.join` as
  /// it comes whatever user is named. A reader that knows no user reads every `presence.join`
  /// as progress.
  public func reading(asUser userId: String) -> EventStream {
    EventStream(member: userId, open: open)
  }
}

/// FrameReading is what one iteration of an event stream reads its frames from.
protocol FrameReading<Event>: AnyObject {
  associatedtype Event: Sendable

  /// next returns the next frame, or nil once the stream is over.
  func next() async throws -> EventFrame<Event>?
}

/// FixedFrames reads a fixed list of frames, then ends. It is not Sendable: it is the state of one
/// `EventStream.Iterator`, read by the one task iterating it and never shared across tasks.
final class FixedFrames<Event: Sendable>: FrameReading {
  private var remaining: ArraySlice<EventFrame<Event>>

  init(_ frames: [EventFrame<Event>]) {
    remaining = frames[...]
  }

  func next() async throws -> EventFrame<Event>? {
    remaining.popFirst()
  }
}
