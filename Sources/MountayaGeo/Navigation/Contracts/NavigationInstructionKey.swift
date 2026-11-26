/// NavigationInstructionKey is every copy key a step's instruction is said with, a closed set, so a
/// host's strings that hold a sentence for each key say every instruction there is
/// (`geo.navigation.instruction-keys`).
///
/// Each maneuver of REST's `ManeuverType` has two keys: its own member, which takes the way's
/// name, and the member followed by `Plain`, which takes nothing and is said where no way is named.
/// A roundabout entered or left with an exit greater than 0 is said with a shared pair instead,
/// `roundaboutExit`, which takes the exit and the name, and `roundaboutExitPlain`, which takes the
/// exit alone. These are the keys a studio's maneuver copy already holds, so that copy resolves
/// them as they are. A waypoint an itinerary's route passes on the way has a pair of its own,
/// `waypoint`, which takes the waypoint's name, and `waypointPlain`, said where it has none.
///
/// The cases are declared in the order of their ids, the order the contract lists them in, and
/// each raw value is its id.
public enum NavigationInstructionKey: String, CaseIterable, Sendable {
  /// continue is continuing onto a named way.
  case `continue`
  /// continuePlain is continuing, where no way is named.
  case continuePlain
  /// depart is departing along a named way.
  case depart
  /// departPlain is departing, where no way is named.
  case departPlain
  /// enterRoundabout is entering a roundabout onto a named way, where it names no exit.
  case enterRoundabout = "enter-roundabout"
  /// enterRoundaboutPlain is entering a roundabout, where it names no exit and no way.
  case enterRoundaboutPlain = "enter-roundaboutPlain"
  /// exitRoundabout is leaving a roundabout onto a named way, where it names no exit.
  case exitRoundabout = "exit-roundabout"
  /// exitRoundaboutPlain is leaving a roundabout, where it names no exit and no way.
  case exitRoundaboutPlain = "exit-roundaboutPlain"
  /// goal is arriving, on a named way.
  case goal
  /// goalPlain is arriving, where no way is named.
  case goalPlain
  /// keepLeft is keeping left onto a named way.
  case keepLeft = "keep-left"
  /// keepLeftPlain is keeping left, where no way is named.
  case keepLeftPlain = "keep-leftPlain"
  /// keepRight is keeping right onto a named way.
  case keepRight = "keep-right"
  /// keepRightPlain is keeping right, where no way is named.
  case keepRightPlain = "keep-rightPlain"
  /// roundaboutExit is taking a roundabout's exit onto a named way.
  case roundaboutExit
  /// roundaboutExitPlain is taking a roundabout's exit, where no way is named.
  case roundaboutExitPlain
  /// sharpLeft is turning sharp left onto a named way.
  case sharpLeft = "sharp-left"
  /// sharpLeftPlain is turning sharp left, where no way is named.
  case sharpLeftPlain = "sharp-leftPlain"
  /// sharpRight is turning sharp right onto a named way.
  case sharpRight = "sharp-right"
  /// sharpRightPlain is turning sharp right, where no way is named.
  case sharpRightPlain = "sharp-rightPlain"
  /// slightLeft is turning slightly left onto a named way.
  case slightLeft = "slight-left"
  /// slightLeftPlain is turning slightly left, where no way is named.
  case slightLeftPlain = "slight-leftPlain"
  /// slightRight is turning slightly right onto a named way.
  case slightRight = "slight-right"
  /// slightRightPlain is turning slightly right, where no way is named.
  case slightRightPlain = "slight-rightPlain"
  /// turnLeft is turning left onto a named way.
  case turnLeft = "turn-left"
  /// turnLeftPlain is turning left, where no way is named.
  case turnLeftPlain = "turn-leftPlain"
  /// turnRight is turning right onto a named way.
  case turnRight = "turn-right"
  /// turnRightPlain is turning right, where no way is named.
  case turnRightPlain = "turn-rightPlain"
  /// unknown is a maneuver outside the contract's set, onto a named way.
  case unknown
  /// unknownPlain is a maneuver outside the contract's set, where no way is named.
  case unknownPlain
  /// uturn is making a U-turn onto a named way.
  case uturn
  /// uturnPlain is making a U-turn, where no way is named.
  case uturnPlain
  /// waypoint is passing a named waypoint on the way, which it takes the name of.
  case waypoint
  /// waypointPlain is passing a waypoint on the way, where it is named nothing.
  case waypointPlain

  /// id is the key as the contract spells it and a host's strings are keyed by.
  public var id: String { rawValue }

  /// arguments is what the key takes, in the order it takes them: the way's name for a
  /// maneuver's own key, the waypoint's for `waypoint`, nothing for a `Plain` one, the exit and the
  /// name for `roundaboutExit`, and the exit alone for `roundaboutExitPlain`.
  public var arguments: [NavigationInstructionArgument] {
    switch self {
    case .roundaboutExit: [.exit, .name]
    case .roundaboutExitPlain: [.exit]
    case .continuePlain, .departPlain, .enterRoundaboutPlain, .exitRoundaboutPlain, .goalPlain,
      .keepLeftPlain, .keepRightPlain, .sharpLeftPlain, .sharpRightPlain, .slightLeftPlain,
      .slightRightPlain, .turnLeftPlain, .turnRightPlain, .unknownPlain, .uturnPlain,
      .waypointPlain:
      []
    case .continue, .depart, .enterRoundabout, .exitRoundabout, .goal, .keepLeft, .keepRight,
      .sharpLeft, .sharpRight, .slightLeft, .slightRight, .turnLeft, .turnRight, .unknown, .uturn,
      .waypoint:
      [.name]
    }
  }
}
