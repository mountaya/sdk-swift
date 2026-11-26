import Testing

@testable import MountayaElements

@Suite("QueryAbort")
struct QueryAbortTests {
  private struct Refused: Error, Equatable {}

  /// Pending is a query that never answers, answering `CancellationError` once its task is
  /// cancelled.
  private static func pending() -> @Sendable () async throws -> Int {
    let (never, continuation) = AsyncStream.makeStream(of: Int.self)
    return {
      defer { continuation.finish() }
      for await value in never {
        return value
      }
      throw CancellationError()
    }
  }

  @Test("a query that answers first is the race's answer")
  func answers() async throws {
    let abort = QueryAbort()

    #expect(try await abort.race { 42 } == 42)
  }

  @Test("a query's own failure is the race's")
  func fails() async {
    let abort = QueryAbort()

    await #expect(throws: Refused()) {
      try await abort.race { () async throws -> Int in throw Refused() }
    }
  }

  @Test(
    "an abort pulled before the query answers ends the race as cancelled, and cancels the query")
  func pulled() async {
    let abort = QueryAbort()
    abort.pull()

    await #expect(throws: CancellationError.self) {
      try await abort.race(Self.pending())
    }
  }

  @Test("an abort pulled while the query waits ends the race at once")
  func pulledWhileWaiting() async {
    let abort = QueryAbort()
    let race = Task { try await abort.race(Self.pending()) }
    abort.pull()

    await #expect(throws: CancellationError.self) {
      try await race.value
    }
  }

  @Test("an abort pulled after the answer changes nothing")
  func pulledAfter() async throws {
    let abort = QueryAbort()
    let answer = try await abort.race { 7 }
    abort.pull()

    #expect(answer == 7)
  }
}
