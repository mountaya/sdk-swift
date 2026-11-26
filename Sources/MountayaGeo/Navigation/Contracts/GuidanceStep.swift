/// GuidanceStep is one step of a followed route as an engine that speaks reads it: how long it is,
/// the maneuver that begins it, and the prompts said along it before the maneuver that ends it,
/// which is the next step's (`geo.navigation.prompts`).
///
/// Two are equal where every member is.
public struct GuidanceStep: Sendable, Equatable {
  /// meters is the step's measured length, as Geo measures the route.
  public let meters: Double
  /// instruction is the maneuver that begins the step, as `stepInstruction(_:)` says it.
  public let instruction: NavigationInstruction
  /// prompts are the prompts said along the step, the farthest from its end first, in the order a
  /// reader finds them due.
  public let prompts: [GuidancePrompt]

  /// Creates the step of `meters` that `instruction` begins, saying `prompts` along it.
  public init(meters: Double, instruction: NavigationInstruction, prompts: [GuidancePrompt]) {
    self.meters = meters
    self.instruction = instruction
    self.prompts = prompts
  }
}
