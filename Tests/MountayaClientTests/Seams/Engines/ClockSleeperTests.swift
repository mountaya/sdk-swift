import Simulation
import Testing

@testable import MountayaClient

@Suite("ClockSleeper")
struct ClockSleeperTests {
  @Test("a wait is measured on the clock the client was given")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func waitsOnTheGivenClock() async throws {
    let elapsed = try await Simulation.run { simulation in
      try await ClockSleeper(clock: simulation.clock).sleep(for: .seconds(90))
      return simulation.elapsed
    }

    #expect(elapsed == .seconds(90))
  }

  @Test("its time is the given clock's, from the moment it was made")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func readsTheGivenClock() async throws {
    let (made, waited) = try await Simulation.run { simulation in
      try await simulation.clock.sleep(for: .seconds(5))
      let sleeper = ClockSleeper(clock: simulation.clock)
      let made = sleeper.now
      try await simulation.clock.sleep(for: .seconds(90))
      return (made, sleeper.now)
    }

    #expect(made == .zero)
    #expect(waited == .seconds(90))
  }

  @Test("a task cancelled before the wait never starts one")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func cancelledBefore() async throws {
    let elapsed = try await Simulation.run { simulation in
      let task = Task(executorPreference: nil) {
        withUnsafeCurrentTask { $0?.cancel() }
        try await ClockSleeper(clock: simulation.clock).sleep(for: .seconds(90))
      }
      let result = await task.result
      #expect(throws: CancellationError.self) { try result.get() }
      return simulation.elapsed
    }

    #expect(elapsed == .zero)
  }
}
