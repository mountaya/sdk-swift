import Synchronization

/// StepClock is a clock whose time moves on only where a sleeper asks it to: each sleep ends at
/// once, the clock standing at the instant it slept until, so a walk paced on it is walked in full
/// as fast as the main actor turns, and the same way on every host. A clock made `late` wakes each
/// sleeper that much after the instant it asked for, as a main actor too busy to wake it on time
/// would, the time standing there.
@available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
struct StepClock: Clock {
  /// Instant is a moment on the clock, its offset from the clock's start.
  struct Instant: InstantProtocol {
    var offset: Duration

    func advanced(by duration: Duration) -> Instant {
      Instant(offset: offset + duration)
    }

    func duration(to other: Instant) -> Duration {
      other.offset - offset
    }

    static func < (lhs: Instant, rhs: Instant) -> Bool {
      lhs.offset < rhs.offset
    }
  }

  /// Time is the clock's time, shared by every copy of it.
  private final class Time: Sendable {
    let offset = Mutex(Duration.zero)
  }

  private let time = Time()
  private let late: Duration

  /// Creates a clock at its start, waking each sleeper `late` after the instant it asked for.
  init(late: Duration = .zero) {
    self.late = late
  }

  var now: Instant { Instant(offset: time.offset.withLock { $0 }) }

  var minimumResolution: Duration { .nanoseconds(1) }

  func sleep(until deadline: Instant, tolerance: Duration? = nil) async throws {
    try Task.checkCancellation()
    let late = late
    time.offset.withLock { offset in
      offset = Swift.max(offset, deadline.offset + late)
    }
    await Task.yield()
    try Task.checkCancellation()
  }
}
