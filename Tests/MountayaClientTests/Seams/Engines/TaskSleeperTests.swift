import Testing

@testable import MountayaClient

@Suite("TaskSleeper")
struct TaskSleeperTests {
  /// A wait long enough that a test which fails to interrupt it is caught by the bound below
  /// instead of passing late.
  private static let longWait: Duration = .seconds(60)
  /// The bound a cancelled wait ends within: half of `longWait`, which still tells a wait cut short
  /// from one that slept in full. It is that wide because it measures the cooperative pool as well
  /// as the sleeper: on Linux, while CPU-heavy suites beside this one saturate the pool, a
  /// cancellation was measured ending 13 s after the wait began, with nothing blocking it.
  private static let promptly: Duration = longWait / 2

  @Test("it waits at least the duration")
  func waitsAtLeastTheDuration() async throws {
    let elapsed = try await ContinuousClock().measure {
      try await TaskSleeper().sleep(for: .milliseconds(30))
    }

    #expect(elapsed >= .milliseconds(30))
  }

  @Test("its time moves on with the continuous clock, at least as far as a wait")
  func readsTheContinuousClock() async throws {
    let sleeper = TaskSleeper()
    let start = sleeper.now

    try await sleeper.sleep(for: .milliseconds(30))

    #expect(start >= .zero)
    #expect(sleeper.now - start >= .milliseconds(30))
  }

  @Test("a task cancelled before the wait never starts one")
  func cancelledBeforeTheWait() async {
    let clock = ContinuousClock()
    let start = clock.now
    let task = Task {
      while !Task.isCancelled {
        await Task.yield()
      }
      try await TaskSleeper().sleep(for: Self.longWait)
    }
    task.cancel()
    let result = await task.result

    #expect(throws: CancellationError.self) { try result.get() }
    #expect(clock.now - start < Self.promptly)
  }

  @Test("a cancellation during the wait ends it at once")
  func cancelledDuringTheWait() async throws {
    let clock = ContinuousClock()
    let start = clock.now
    let task = Task {
      try await TaskSleeper().sleep(for: Self.longWait)
    }
    try await Task.sleep(for: .milliseconds(50))
    task.cancel()
    let result = await task.result

    #expect(throws: CancellationError.self) { try result.get() }
    #expect(clock.now - start < Self.promptly)
  }
}
