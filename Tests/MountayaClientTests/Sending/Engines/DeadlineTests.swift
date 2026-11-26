import Simulation
import Testing

@testable import MountayaClient

@Suite("Deadline")
struct DeadlineTests {
  private struct Failed: Error {}

  @Test(
    "an operation that finishes in time is answered, one that does not is expired at its budget")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func race() async throws {
    let (inTime, late, at) = try await Simulation.run { simulation in
      let sleeper = ClockSleeper(clock: simulation.clock)
      let inTime = try await Deadline.run(within: .seconds(1), sleeper: sleeper) {
        try await simulation.clock.sleep(for: .milliseconds(999))
        return 1
      }
      let start = simulation.elapsed
      let late = try await Deadline.run(within: .seconds(1), sleeper: sleeper) {
        try await simulation.clock.sleep(for: .seconds(60))
        return 2
      }
      return (inTime, late, simulation.elapsed - start)
    }

    guard case .finished(1) = inTime, case .expired = late else {
      Issue.record("the race was decided the wrong way")
      return
    }
    #expect(at == .seconds(1))
  }

  @Test("a failure throws through, and a cancelled caller is never read as a spent budget")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func failures() async throws {
    try await Simulation.run { simulation in
      let sleeper = ClockSleeper(clock: simulation.clock)
      await #expect(throws: Failed.self) {
        _ = try await Deadline.run(within: .seconds(1), sleeper: sleeper) {
          () async throws -> Int in throw Failed()
        }
      }
      await withThrowingTaskGroup(of: Void.self) { group in
        group.addTask {
          await #expect(throws: CancellationError.self) {
            _ = try await Deadline.run(within: .seconds(10), sleeper: sleeper) {
              try await simulation.clock.sleep(for: .seconds(60))
            }
          }
        }
        group.addTask { try await simulation.clock.sleep(for: .seconds(1)) }
        _ = try? await group.next()
        group.cancelAll()
      }
    }
  }
}
