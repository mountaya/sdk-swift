/// NavigationInstructionArgument is what an instruction's copy key may take besides itself: the
/// way's name, and a roundabout's exit (`geo.navigation.instruction-keys`). A host's strings put
/// each where their language's grammar does.
public enum NavigationInstructionArgument: String, CaseIterable, Sendable {
  /// exit is the roundabout exit to take, from 1.
  case exit
  /// name is the name of the way the step follows, or of the waypoint a `waypoint` step passes.
  case name

  /// id is the argument as the contract names it in a key's arguments.
  public var id: String { rawValue }
}
