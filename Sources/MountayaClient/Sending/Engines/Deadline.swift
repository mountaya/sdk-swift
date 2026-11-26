/// Deadline runs an operation against a time budget, the deadline the transport holds itself
/// for every attempt and every read of an event stream.
///
/// An idle interval would let a server that writes a byte a minute hold an attempt for ever,
/// which is why the budget is a deadline from the start of the operation and not a timeout
/// between two reads.
enum Deadline {
  /// Raced is how an operation run against a deadline ended.
  enum Raced<Value: Sendable>: Sendable {
    /// finished is the operation's own value.
    case finished(Value)
    /// expired is a budget spent before the operation finished, which was then cancelled.
    case expired
  }

  /// run returns what `operation` returns, or `expired` where `budget` runs out first.
  ///
  /// An operation that throws before the budget runs out throws through, and a cancelled
  /// calling task throws `CancellationError`, which is never read as a spent budget.
  static func run<Value: Sendable>(
    within budget: Duration,
    sleeper: any Sleeper,
    operation: @escaping @Sendable () async throws -> Value
  ) async throws -> Raced<Value> {
    try await withThrowingTaskGroup(of: Raced<Value>.self) { group in
      group.addTask { .finished(try await operation()) }
      group.addTask {
        try await sleeper.sleep(for: budget)
        return .expired
      }
      defer { group.cancelAll() }
      guard let first = try await group.next() else { return .expired }
      return first
    }
  }
}
