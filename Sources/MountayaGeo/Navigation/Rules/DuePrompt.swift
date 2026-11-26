/// promptSlackMeters is how far short of its trigger a prompt already falls due, in meters, so a
/// prompt read a little early is said rather than missed between two positions: the
/// `promptSlackMeters` `geo/navigation-prompts.json` declares.
public let promptSlackMeters = 5.0

/// duePrompt is the prompt of `plan` due where the traveller stands, `progress` being where Geo
/// reads them on the route the plan lays out (`geo.navigation.progress`), or nil before any
/// position is read there; nil where none is due.
///
/// The step read is the one `progress` names, held within the plan, and the first before any
/// position, where the traveller stands at the route's start. The distance read is what is left to
/// that step's end, `NavigationProgress.toManeuver`, measured from the traveller's foot on the
/// route, which never moves back and is found on every stretch ahead, and the whole step before
/// any position. A prompt is due where that distance less its trigger, `GuidancePrompt.meters`, is
/// `promptSlackMeters` or less, and of the step's prompts due the last wins: the farther a prompt
/// stands from its step's end the earlier it comes, so the one nearest the maneuver is the one
/// standing.
///
/// That is the rule every SDK's guidance reads over the same plan (`geo.navigation.prompts`), so a
/// prompt is said at the meter Geo's progress names, which every SDK reads alike, and an engine an
/// app writes that speaks reads it as `DeviceNavigationEngine` does.
public func duePrompt(_ plan: GuidancePlan, progress: NavigationProgress?) -> GuidancePrompt? {
  guard !plan.steps.isEmpty else { return nil }
  let step = plan.steps[Swift.min(Swift.max(progress?.step ?? 0, 0), plan.steps.count - 1)]
  let left = progress?.toManeuver.distance ?? step.meters
  return step.prompts.last { left - $0.meters <= promptSlackMeters }
}
