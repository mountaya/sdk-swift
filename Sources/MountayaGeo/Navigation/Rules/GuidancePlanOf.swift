/// promptMeters is how far before a maneuver its prompt is said: about half a minute ahead at a
/// walker's pace, and ten seconds at a cyclist's. A step shorter than that says the maneuver that
/// ends it as the traveller enters it. It is the `promptMeters` `geo/navigation-prompts.json`
/// declares.
public let promptMeters = 50.0

/// guidancePlanOf lays a followed route out as the guidance reads it, or answers nil where no
/// vertex of its line names a place, which leaves nothing to guide.
///
/// Each step is the followed route's own, its length read off the lengths the route was measured
/// with once, when it was followed, its `measured` line, so a step's length is the one the
/// traveller is told and the line is never measured again. The prompts announce each maneuver from
/// the step that leads to it, `promptMeters` before its end or as the step begins where it is
/// shorter, and the first step announces its own departure as it begins, ahead of the maneuver
/// that ends it. The last step leads to no maneuver, and announces none.
///
/// A step of no length is never where the traveller is read with ground left to cover, so it keeps
/// no prompt, and what it would announce is said from a step of length:
///
/// - after a step of length, from the nearest such step before it, after that step's own prompts
///   and after any moved there before, each due as that step ends, at the vertex the maneuvers
///   share: two maneuvers on one vertex are said in order, the first `promptMeters` out and the
///   second at the vertex, and of three or more the first and the last are said and those between
///   are not, since of a step's prompts due the last wins and each is said once;
/// - where the route opens with steps of no length, from its first step of length, before that
///   step's own prompts, each due as that step begins, and the departure, which covers no ground,
///   is dropped: as the walk begins the last maneuver of the opening vertex is said, or the one
///   that ends the first step of length where that step is short enough for it to be due there too.
///
/// A route with no step of length, one of a single vertex, keeps every prompt where it is laid. The
/// prompts are numbered from 0 in travel order once moved.
///
/// It is the plan every SDK's guidance lays out, prompt for prompt (`geo.navigation.prompts`), and
/// the one an engine an app writes that speaks lays out as `DeviceNavigationEngine` does.
public func guidancePlanOf(_ route: FollowedRoute) -> GuidancePlan? {
  guard route.line.contains(where: namesPlace) else { return nil }
  let measured = route.measured
  let steps = route.steps
  let lengths = steps.map { measured[$0.toIndex] - measured[$0.fromIndex] }
  let instructions = steps.map(stepInstruction)
  let hasLength = lengths.contains { $0 > 0 }
  var laid = [[(instruction: NavigationInstruction, meters: Double)]](
    repeating: [], count: steps.count)
  // The maneuvers of the steps of no length that open the route, waiting for its first of length.
  var opening: [NavigationInstruction] = []
  var lastWithLength: Int?
  for index in steps.indices {
    let meters = lengths[index]
    // A step announces the maneuver that ends it, which is the next step's.
    let ending = index + 1 < steps.count ? instructions[index + 1] : nil
    if !hasLength || meters > 0 {
      var prompts = opening.map { (instruction: $0, meters: meters) }
      opening = []
      if index == 0 {
        prompts.append((instructions[0], meters))
      }
      if let ending {
        prompts.append((ending, Swift.min(promptMeters, meters)))
      }
      laid[index] = prompts
      if meters > 0 { lastWithLength = index }
    } else if let earlier = lastWithLength {
      if let ending { laid[earlier].append((ending, 0)) }
    } else if let ending {
      opening.append(ending)
    }
  }
  var nextPrompt = 0
  var planned: [GuidanceStep] = []
  planned.reserveCapacity(steps.count)
  for index in steps.indices {
    let prompts = laid[index].map { prompt in
      defer { nextPrompt += 1 }
      return GuidancePrompt(id: nextPrompt, instruction: prompt.instruction, meters: prompt.meters)
    }
    planned.append(
      GuidanceStep(meters: lengths[index], instruction: instructions[index], prompts: prompts))
  }
  return GuidancePlan(steps: planned)
}
