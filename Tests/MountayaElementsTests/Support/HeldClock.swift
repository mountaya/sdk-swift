import Synchronization

/// HeldClock is a clock a test moves by hand: it stands still until `advance(by:)` moves it, waking
/// each sleep due on the way, so a wait of 35 seconds is told from one of 34.999 with no real time
/// passing.
@available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
final class HeldClock: Clock, Sendable {
  /// Instant is an offset from the clock's start.
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

  /// Sleeping is one sleep begun and not yet over.
  private struct Sleeping {
    let id: Int
    let deadline: Duration
    let continuation: CheckedContinuation<Void, any Error>
  }

  /// State is the time passed and every sleep waiting on it.
  private struct State {
    var now: Duration = .zero
    var nextId = 0
    var sleeping: [Sleeping] = []
  }

  private let state = Mutex(State())

  var now: Instant {
    Instant(offset: state.withLock { $0.now })
  }

  var minimumResolution: Duration { .zero }

  /// sleepers is how many sleeps wait on the clock.
  var sleepers: Int {
    state.withLock { $0.sleeping.count }
  }

  func sleep(until deadline: Instant, tolerance: Duration?) async throws {
    try Task.checkCancellation()
    let id = state.withLock { held -> Int in
      held.nextId += 1
      return held.nextId
    }
    try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { continuation in
        let due = state.withLock { held -> Bool in
          guard deadline.offset > held.now else { return true }
          held.sleeping.append(
            Sleeping(id: id, deadline: deadline.offset, continuation: continuation))
          return false
        }
        if due { continuation.resume() }
      }
    } onCancel: {
      let cancelled = state.withLock { held -> Sleeping? in
        guard let index = held.sleeping.firstIndex(where: { $0.id == id }) else { return nil }
        return held.sleeping.remove(at: index)
      }
      cancelled?.continuation.resume(throwing: CancellationError())
    }
  }

  /// advance moves the time `duration` on and wakes every sleep due by then.
  func advance(by duration: Duration) {
    let due = state.withLock { held -> [Sleeping] in
      held.now += duration
      let now = held.now
      let due = held.sleeping.filter { $0.deadline <= now }
      held.sleeping.removeAll { $0.deadline <= now }
      return due
    }
    for sleep in due {
      sleep.continuation.resume()
    }
  }
}
