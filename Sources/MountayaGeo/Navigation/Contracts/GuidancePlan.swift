/// GuidancePlan is a followed route as an engine that speaks reads it: its steps, the followed
/// route's own, one for one and in the same order, each with the prompts said along it
/// (`geo.navigation.prompts`).
///
/// Two are equal where every step is.
public struct GuidancePlan: Sendable, Equatable {
  /// steps is the route's steps, one for each of the followed route's.
  public let steps: [GuidanceStep]

  /// Creates the plan of `steps`, such as a test's own; `guidancePlanOf(_:)` lays a route's out.
  public init(steps: [GuidanceStep]) {
    self.steps = steps
  }
}
