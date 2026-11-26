/// VirtualClock is a simulation's clock: its instants are offsets from the simulation's start,
/// and a sleep on it ends when the simulation reaches its deadline.
@available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
public struct VirtualClock: Clock {
  /// Instant is an offset from the simulation's start.
  public struct Instant: InstantProtocol {
    /// offset is how long after the start the instant lies.
    public var offset: Duration

    /// Creates the instant `offset` after the start.
    public init(offset: Duration) {
      self.offset = offset
    }

    /// advanced returns the instant `duration` later.
    public func advanced(by duration: Duration) -> Instant {
      Instant(offset: offset + duration)
    }

    /// duration returns how long it is from this instant to `other`.
    public func duration(to other: Instant) -> Duration {
      other.offset - offset
    }

    /// One instant is before another where its offset is smaller.
    public static func < (lhs: Instant, rhs: Instant) -> Bool {
      lhs.offset < rhs.offset
    }
  }

  let timeline: Timeline

  /// now is the simulation's current instant.
  public var now: Instant {
    Instant(offset: timeline.now)
  }

  /// minimumResolution is no time at all: the simulation reaches an instant exactly.
  public var minimumResolution: Duration {
    .zero
  }

  /// sleep suspends the calling task until the simulation reaches `deadline`, and throws
  /// `CancellationError` as soon as the task is cancelled. A deadline already reached returns at
  /// once.
  public func sleep(until deadline: Instant, tolerance: Duration? = nil) async throws {
    try Task.checkCancellation()
    guard deadline.offset > timeline.now else { return }
    let id = timeline.nextTimer()
    try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation {
        (continuation: CheckedContinuation<Void, any Error>) in
        timeline.schedule(id, at: deadline.offset, resuming: continuation)
      }
    } onCancel: {
      timeline.cancel(id)
    }
  }
}
