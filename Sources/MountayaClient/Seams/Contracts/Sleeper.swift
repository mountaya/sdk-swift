/// Sleeper is the seam through which the client waits, and on whose clock it measures how long
/// something has lasted.
///
/// A wait is interruptible: cancelling the task that waits ends the wait at once, and a task
/// that is already cancelled never starts one.
protocol Sleeper: Sendable {
  /// now is the time on the clock the seam waits on, as the span since a moment of its own
  /// choosing: only the difference between two readings means anything.
  var now: Duration { get }

  /// sleep suspends the calling task for the duration, and throws `CancellationError` as soon
  /// as that task is cancelled, whether before the wait or during it.
  func sleep(for duration: Duration) async throws
}
