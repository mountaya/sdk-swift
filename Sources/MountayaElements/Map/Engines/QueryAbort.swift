/// QueryAbort abandons the query a call of the map runs, once the map pulls it: a re-run of the
/// result asking again, its removal, or a clear of its kind (`map.analysis.requests`).
///
/// The call races its query against the abort in a group of its own task, so the query runs in the
/// caller's task, and is cancelled as the abort is pulled, the call throwing `CancellationError`.
/// It is Sendable: its stored properties are constants of Sendable types.
final class QueryAbort: Sendable {
  /// signal ends once the abort is pulled.
  let signal: AsyncStream<Void>
  private let continuation: AsyncStream<Void>.Continuation

  /// Creates an abort no one pulled.
  init() {
    (signal, continuation) = AsyncStream.makeStream(of: Void.self)
  }

  /// pull abandons the query, at once.
  func pull() {
    continuation.yield()
    continuation.finish()
  }

  /// race runs `query` in the calling task and answers what it answers, or throws
  /// `CancellationError` where the abort is pulled first, the query cancelled.
  func race<Answer: Sendable>(_ query: @escaping @Sendable () async throws -> Answer)
    async throws -> Answer
  {
    let signal = signal
    return try await withThrowingTaskGroup(of: Answer?.self) { group in
      group.addTask { try await query() }
      group.addTask {
        for await _ in signal { break }
        return nil
      }
      defer { group.cancelAll() }
      guard let first = try await group.next(), let answer = first else {
        throw CancellationError()
      }
      return answer
    }
  }
}
