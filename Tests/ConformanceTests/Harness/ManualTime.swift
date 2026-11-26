/// ManualTime is time a script moves by hand, for an engine bound to the main actor whose pauses a
/// fixture measures: it stands still until `advance(by:settling:)` moves it, waking each wait due on
/// the way at its deadline, earliest first, those of one deadline in the order they began, and
/// letting what each wakes come to rest before moving on.
///
/// Its wait runs on the main actor, so a task waiting on it wakes there and nowhere else, and a
/// script waits for nothing in real time: a pause of 150 ms and one of 149 are told apart exactly,
/// the same way on every host. It is the harness's own time and nothing a product reaches.
@MainActor
final class ManualTime {
  private struct Waiting {
    let id: Int
    let deadline: Duration
    let continuation: CheckedContinuation<Void, any Error>
  }

  /// now is how much time has passed since the start.
  private(set) var now: Duration = .zero
  private var nextId = 0
  private var waiting: [Waiting] = []

  /// deadlines is when each wait begun and not yet over ends, in the order they began, which a
  /// script reads among what it waits on to stand still.
  var deadlines: [Duration] { waiting.map(\.deadline) }

  /// sleep is the wait an engine is handed: it returns once the time has moved `duration` on, at
  /// once for none, and throws `CancellationError` once its task is cancelled.
  var sleep: @MainActor @Sendable (Duration) async throws -> Void {
    { [self] duration in try await wait(duration) }
  }

  private func wait(_ duration: Duration) async throws {
    try Task.checkCancellation()
    guard duration > .zero else { return }
    let id = nextId
    nextId += 1
    let deadline = now + duration
    try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { continuation in
        waiting.append(Waiting(id: id, deadline: deadline, continuation: continuation))
      }
    } onCancel: {
      Task { @MainActor in self.cancel(id) }
    }
  }

  /// cancel ends the wait `id` with `CancellationError`, where it still waits.
  private func cancel(_ id: Int) {
    guard let index = waiting.firstIndex(where: { $0.id == id }) else { return }
    waiting.remove(at: index).continuation.resume(throwing: CancellationError())
  }

  /// advance moves the time `duration` on, waking each wait due on the way at its deadline,
  /// earliest first, and letting what each wakes come to rest, `settle`, before moving on. It first
  /// lets what the script set going come to rest, so a wait a task is about to begin starts at the
  /// time it was asked at.
  func advance(by duration: Duration, settling settle: () async -> Void) async {
    await settle()
    let target = now + duration
    while let earliest = waiting.map(\.deadline).filter({ $0 <= target }).min() {
      now = max(now, earliest)
      let due = waiting.filter { $0.deadline == earliest }.sorted { $0.id < $1.id }
      waiting.removeAll { $0.deadline == earliest }
      for wait in due {
        wait.continuation.resume()
      }
      await settle()
    }
    now = max(now, target)
  }
}
