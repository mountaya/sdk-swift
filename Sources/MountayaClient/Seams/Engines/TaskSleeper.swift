/// TaskSleeper waits by suspending the calling task, and reads the time on the continuous clock
/// a task's wait is measured on, which goes on counting while the device sleeps.
struct TaskSleeper: Sleeper {
  private let origin = ContinuousClock.now

  var now: Duration {
    origin.duration(to: .now)
  }

  func sleep(for duration: Duration) async throws {
    // Checked first so that a task cancelled before the wait never arms a timer at all.
    try Task.checkCancellation()
    try await Task.sleep(for: duration)
  }
}
