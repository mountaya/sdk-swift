/// ClockSleeper waits on a clock the client was given, such as a test's own, and reads the time
/// on it.
struct ClockSleeper: Sleeper {
  private let reading: @Sendable () -> Duration
  private let waiting: @Sendable (Duration) async throws -> Void

  /// Creates a sleeper on `clock`, whose time it reads from the moment it is made.
  init<C: Clock<Duration>>(clock: C) {
    let origin = clock.now
    reading = { origin.duration(to: clock.now) }
    waiting = { try await clock.sleep(for: $0) }
  }

  var now: Duration {
    reading()
  }

  func sleep(for duration: Duration) async throws {
    // Checked first so that a task cancelled before the wait never arms a timer at all.
    try Task.checkCancellation()
    try await waiting(duration)
  }
}
