import GateSupport

/// RunnerTable is where a runner is declared, which decides how it may reach the SDK.
enum RunnerTable: String, Sendable {
  /// A runner under `Runners/Public/`, which reaches the SDK through a plain `import` and so
  /// proves a consumer can reach the capability.
  case `public`
  /// A runner under `Runners/Internal/`, which may reach internals through `@testable import`.
  case `internal`
}

/// RunnerOutcome is what this SDK answered for one case.
enum RunnerOutcome: Sendable {
  /// The value the SDK produced, in the shape of the fixture's `expect`.
  case value(OrderedJSON)
  /// The contract's name for the class of the error the SDK refused with.
  case refused(String)
  /// The values the SDK produced, in an order of its own, which the fixture's array is held to as
  /// a set: each value it expects matched by one produced, and none produced left over.
  case members([OrderedJSON])
}

/// Runner runs the cases of one capability against this SDK.
struct Runner: Sendable {
  /// id is the registry's id for the capability the runner proves.
  let id: String
  let table: RunnerTable
  let run: @Sendable (Fixture, FixtureCase) async throws -> RunnerOutcome
}
