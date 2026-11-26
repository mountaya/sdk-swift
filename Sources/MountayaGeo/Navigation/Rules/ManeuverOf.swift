import MountayaClient

/// navigationManeuvers is every member of REST's `ManeuverType` this build spells, in the order of
/// their values: what the steps' adapters recognise a maneuver by, and what an instruction has a
/// key for.
let navigationManeuvers: [RestSchema.ManeuverType] = [
  .continue,
  .depart,
  .enterRoundabout,
  .exitRoundabout,
  .goal,
  .keepLeft,
  .keepRight,
  .sharpLeft,
  .sharpRight,
  .slightLeft,
  .slightRight,
  .turnLeft,
  .turnRight,
  .unknown,
  .uturn,
]

/// restManeuvers is the members by their REST spelling.
private let restManeuvers: [String: RestSchema.ManeuverType] = Dictionary(
  uniqueKeysWithValues: navigationManeuvers.map { ($0.rawValue, $0) })

/// dataManeuvers is the members by their Data API spelling. The transform is the contract's own: a
/// REST member is its SDL member lowercased with each underscore turned into a hyphen, so the SDL
/// member is the REST member uppercased with each hyphen turned into an underscore. Every member
/// is ASCII.
private let dataManeuvers: [String: RestSchema.ManeuverType] = Dictionary(
  uniqueKeysWithValues: navigationManeuvers.map {
    (String($0.rawValue.uppercased().map { $0 == "-" ? "_" : $0 }), $0)
  })

/// maneuverOf answers the maneuver `type` names as REST spells it: the member of the contract's
/// set it is, or `unknown` where this build spells no member that way, a member the API added
/// since or another surface's spelling (`TURN_LEFT`). Matched exactly, scalar for scalar, letter
/// case included.
func maneuverOf(_ type: RestSchema.ManeuverType) -> RestSchema.ManeuverType {
  matched(type.rawValue, in: restManeuvers)
}

/// dataManeuverOf answers the REST member the Data API's `type` names, as SCREAMING_SNAKE spells
/// it: `TURN_LEFT` is `turn-left`. A value the Data API does not spell, a member it added since or
/// REST's own spelling (`turn-left`), reads as `unknown`, and so does a step that states none.
func dataManeuverOf(_ type: DataSchema.ManeuverType?) -> RestSchema.ManeuverType {
  guard let type else { return .unknown }
  return matched(type.rawValue, in: dataManeuvers)
}

/// matched answers the member a table spells exactly as `spelling` is written, or `unknown`. A
/// dictionary finds a key by canonical equivalence, so the member it finds is held to the
/// spelling's scalars.
private func matched(_ spelling: String, in table: [String: RestSchema.ManeuverType])
  -> RestSchema.ManeuverType
{
  guard let index = table.index(forKey: spelling), sameText(table[index].key, spelling) else {
    return .unknown
  }
  return table[index].value
}
