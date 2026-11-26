import Foundation

/// MainQueue runs every job of a task that prefers it on the main queue, behind every job already
/// queued there, so the work a map engine hands its client runs in one order with the engine's own,
/// on one thread, and a script's step settles once what it observes stands still.
///
/// A map engine is bound to the main actor, and its client's own code is not: a read the engine
/// sends would otherwise run its transport on the shared pool, beside the main actor, and a script
/// that holds reads open could not tell a read still on its way from one that will never come. A
/// runner starts each call of a script in a task preferring this executor, and settles a step with
/// `settle(observing:)`, which waits in `Quiescence`'s rounds until what the script reads, its
/// calls' outcomes, the reads its exchange holds and what the map draws, stands still: a task the
/// engine starts of its own prefers no executor, so its hop to the client may still cross the pool.
/// The queue is the platform's own main queue, which the main actor's jobs share, so one order holds
/// both. It is the harness's own executor and nothing a product reaches.
@available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
final class MainQueue: TaskExecutor {
  /// shared is the one executor every script prefers.
  static let shared = MainQueue()

  func enqueue(_ job: consuming ExecutorJob) {
    let job = UnownedJob(job)
    let executor = asUnownedTaskExecutor()
    DispatchQueue.main.async {
      job.runSynchronously(on: executor)
    }
  }

  /// run starts `body` in a task of its own that prefers the main queue, so its client's work runs
  /// there too, and answers the task.
  @MainActor
  static func run<Success: Sendable>(
    _ body: @escaping @MainActor @Sendable () async throws -> Success
  ) -> Task<Success, any Error> {
    Task(executorPreference: shared, operation: body)
  }

  /// settle lets what a step set going come to rest, reading `observed` until it stands still.
  @MainActor
  static func settle<Observed: Equatable>(observing observed: () -> Observed) async {
    await Quiescence.settle(observing: observed)
  }
}
