import Foundation
import Synchronization

/// SimulationExecutor runs every job of a simulation, one at a time, on a thread of its own, and
/// moves the simulation's time on whenever it has nothing left to run. It is Sendable, as every
/// executor is: its state sits behind a lock, read by its own thread and by the tasks that enqueue
/// work on it.
@available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
final class SimulationExecutor: TaskExecutor {
  /// idleLimit is how long the executor waits, in real time, for work from outside the
  /// simulation before it calls the body stalled.
  private static let idleLimit: TimeInterval = 20

  private struct State: Sendable {
    var jobs: [UnownedJob] = []
    var isFinished = false
    var didStall = false
    var onStall: (@Sendable () -> Void)?
  }

  private let state = Mutex(State())
  private let timeline: Timeline

  init(timeline: Timeline) {
    self.timeline = timeline
  }

  func enqueue(_ job: consuming ExecutorJob) {
    let unowned = UnownedJob(job)
    state.withLock { $0.jobs.append(unowned) }
  }

  /// didStall is true where the body was cancelled for waiting on nothing the clock brings.
  var didStall: Bool {
    state.withLock { $0.didStall }
  }

  /// onStall is what the executor does where the body stalls.
  func onStall(_ action: @escaping @Sendable () -> Void) {
    state.withLock { $0.onStall = action }
  }

  /// finish ends the loop.
  func finish() {
    state.withLock { $0.isFinished = true }
  }

  /// loop runs jobs until the simulation is finished, moving time on whenever none is left.
  func loop() {
    var idleSince: Date?
    while true {
      let next = state.withLock { state -> (job: UnownedJob?, finished: Bool) in
        state.jobs.isEmpty ? (nil, state.isFinished) : (state.jobs.removeFirst(), false)
      }
      if let job = next.job {
        idleSince = nil
        job.runSynchronously(on: asUnownedTaskExecutor())
        continue
      }
      if next.finished {
        return
      }
      if timeline.advance() {
        idleSince = nil
        continue
      }
      let started = idleSince ?? Date()
      idleSince = started
      if Date().timeIntervalSince(started) > Self.idleLimit {
        idleSince = nil
        let stall = state.withLock { state -> (@Sendable () -> Void)? in
          state.didStall = true
          return state.onStall
        }
        stall?()
      }
      Thread.sleep(forTimeInterval: 0.0002)
    }
  }
}
