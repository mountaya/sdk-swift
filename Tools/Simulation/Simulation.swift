import Foundation

/// Simulation runs an asynchronous body on time it controls, so a test of a deadline, a wait or
/// a stall measures the milliseconds a fixture names without waiting for any of them.
///
/// Every task of the body runs on one serial executor, and the clock moves only when that
/// executor has nothing left to run: then it jumps to the earliest instant a task sleeps until
/// and wakes the tasks sleeping until it. Two sleepers that wake at one instant wake in the order
/// they went to sleep, so a run is the same on every host and on every repeat. A task the body
/// creates with `Task {}` leaves the simulation, so code run in one keeps to structured
/// concurrency.
///
/// It is Sendable: its stored properties are constants of Sendable types, the clock and the
/// timeline it reads.
@available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
public final class Simulation: Sendable {
  /// Stalled is the failure of a body that waited on something no simulated instant brings.
  public struct Stalled: Error, CustomStringConvertible {
    /// description says what stalled.
    public var description: String {
      "the simulated body waited on something no simulated instant brings"
    }
  }

  /// clock is the simulation's clock, which every sleep of the body is measured on.
  public let clock: VirtualClock
  let timeline: Timeline

  private init() {
    timeline = Timeline()
    clock = VirtualClock(timeline: timeline)
  }

  /// elapsed is how much simulated time has passed since the body started.
  public var elapsed: Duration {
    timeline.now
  }

  /// run runs `body` in a simulation of its own and returns what it returns, or throws
  /// `Stalled` where the body waits on nothing the clock brings.
  public static func run<Result: Sendable>(
    _ body: @escaping @Sendable (Simulation) async throws -> Result
  ) async throws -> Result {
    let simulation = Simulation()
    let executor = SimulationExecutor(timeline: simulation.timeline)
    let thread = Thread { executor.loop() }
    thread.start()
    let task = Task(executorPreference: executor) {
      // The body ends the executor itself, on the executor's own thread, the moment it returns
      // or throws. The caller awaiting the task's result resumes on the shared pool, which a
      // loaded host may not schedule for seconds, and an executor still running by then would
      // count that wait as the body's own and call a finished body stalled.
      defer { executor.finish() }
      return try await body(simulation)
    }
    executor.onStall { task.cancel() }
    let result = await task.result
    executor.finish()
    if executor.didStall {
      throw Stalled()
    }
    return try result.get()
  }
}
