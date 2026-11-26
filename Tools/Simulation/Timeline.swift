import Synchronization

/// Timeline is a simulation's time: the instant it has reached, and every sleeper waiting for a
/// later one. It is Sendable: its instant and its sleepers sit behind a lock.
@available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
final class Timeline: Sendable {
  private struct Timer: Sendable {
    let id: Int
    let deadline: Duration
    let continuation: CheckedContinuation<Void, any Error>
  }

  private struct State: Sendable {
    var now: Duration = .zero
    var nextId = 0
    var timers: [Timer] = []
    var cancelled: Set<Int> = []
  }

  private let state = Mutex(State())

  /// now is the instant the simulation has reached.
  var now: Duration {
    state.withLock { $0.now }
  }

  /// hasTimers is true while a sleeper waits.
  var hasTimers: Bool {
    state.withLock { !$0.timers.isEmpty }
  }

  /// nextTimer returns the id of a sleep about to start.
  func nextTimer() -> Int {
    state.withLock { state in
      defer { state.nextId += 1 }
      return state.nextId
    }
  }

  /// schedule wakes `continuation` once the simulation reaches `deadline`, or at once with
  /// `CancellationError` where its sleep was cancelled before it started.
  func schedule(
    _ id: Int, at deadline: Duration, resuming continuation: CheckedContinuation<Void, any Error>
  ) {
    let refused = state.withLock { state -> Bool in
      if state.cancelled.remove(id) != nil {
        return true
      }
      state.timers.append(Timer(id: id, deadline: deadline, continuation: continuation))
      return false
    }
    if refused {
      continuation.resume(throwing: CancellationError())
    }
  }

  /// cancel ends the sleep `id` with `CancellationError`.
  func cancel(_ id: Int) {
    let timer = state.withLock { state -> Timer? in
      guard let index = state.timers.firstIndex(where: { $0.id == id }) else {
        state.cancelled.insert(id)
        return nil
      }
      return state.timers.remove(at: index)
    }
    timer?.continuation.resume(throwing: CancellationError())
  }

  /// advance moves the simulation to the earliest deadline a sleeper waits for and wakes every
  /// sleeper waiting for it, in the order they went to sleep, and returns false where none waits.
  func advance() -> Bool {
    let woken = state.withLock { state -> [Timer] in
      guard let earliest = state.timers.map(\.deadline).min() else { return [] }
      state.now = max(state.now, earliest)
      let due = state.timers.filter { $0.deadline == earliest }.sorted { $0.id < $1.id }
      state.timers.removeAll { $0.deadline == earliest }
      return due
    }
    for timer in woken {
      timer.continuation.resume()
    }
    return !woken.isEmpty
  }
}
