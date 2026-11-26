import MountayaClient

/// namedKeys is the key each maneuver of the contract's set is said with where a way is named:
/// its own member.
private let namedKeys: [RestSchema.ManeuverType: NavigationInstructionKey] = Dictionary(
  uniqueKeysWithValues: navigationManeuvers.map {
    ($0, NavigationInstructionKey(rawValue: $0.rawValue) ?? .unknown)
  })

/// plainKeys is the key each maneuver of the contract's set is said with where no way is named:
/// its `Plain` twin.
private let plainKeys: [RestSchema.ManeuverType: NavigationInstructionKey] = Dictionary(
  uniqueKeysWithValues: navigationManeuvers.map {
    ($0, NavigationInstructionKey(rawValue: $0.rawValue + "Plain") ?? .unknownPlain)
  })

/// stepInstruction answers the copy key a step's instruction is said with, and the arguments the
/// key takes, never the sentence: the words are the host's strings'
/// (`geo.navigation.instruction-keys`).
///
/// A way is named where the step's name is a string other than the empty one and `-`, the API's
/// word for an unnamed way. A roundabout, `enter-roundabout` or `exit-roundabout`, with an exit
/// greater than 0 is said with the exit, since the exit is what a traveller needs there:
/// `roundaboutExit` with the exit and the name, or `roundaboutExitPlain` with the exit alone. Any
/// other maneuver is said with its own key and the name, or its `Plain` twin where no way is
/// named; an exit on any other maneuver, and one of 0 or less, names nothing. A `waypoint`, which
/// the vocabulary holds beside the contract's set and no surface writes, is said by the same rule:
/// `waypoint` with its name, the waypoint's, or `waypointPlain`. A maneuver outside the
/// vocabulary, a step written by hand included, is said as `unknown`.
public func stepInstruction(_ step: NavigationStep) -> NavigationInstruction {
  let name = wayName(step.name)
  if sameText(step.maneuver.rawValue, RestSchema.ManeuverType.waypoint.rawValue) {
    guard let name else { return NavigationInstruction(key: .waypointPlain) }
    return NavigationInstruction(key: .waypoint, name: name)
  }
  let maneuver = maneuverOf(step.maneuver)
  let isRoundabout =
    maneuver == .enterRoundabout || maneuver == .exitRoundabout
  if isRoundabout, let exit = step.exitNumber, exit > 0 {
    guard let name else { return NavigationInstruction(key: .roundaboutExitPlain, exit: exit) }
    return NavigationInstruction(key: .roundaboutExit, name: name, exit: exit)
  }
  guard let name else { return NavigationInstruction(key: plainKeys[maneuver] ?? .unknownPlain) }
  return NavigationInstruction(key: namedKeys[maneuver] ?? .unknown, name: name)
}
