/// GuidancePrompt is one maneuver said aloud before the traveller reaches it: the instruction
/// said, and how far before the end of the step that leads to it the prompt falls due, its
/// trigger, as `duePrompt(_:progress:)` reads it (`geo.navigation.prompts`).
///
/// Two are equal where they hold one place, one instruction and the same distance.
public struct GuidancePrompt: Sendable, Equatable {
  /// id is the prompt's place among every prompt of its route, counted from 0 in travel order.
  public let id: Int
  /// instruction is the maneuver said.
  public let instruction: NavigationInstruction
  /// meters is the distance before the end of its step at which the prompt is due, its trigger.
  public let meters: Double

  /// Creates the prompt `id` saying `instruction`, due `meters` before the end of its step.
  public init(id: Int, instruction: NavigationInstruction, meters: Double) {
    self.id = id
    self.instruction = instruction
    self.meters = meters
  }
}
