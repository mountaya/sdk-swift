import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("duePrompt")
struct DuePromptTests {
  /// turning departs east for about 1,112 m, turns north for as long, and arrives at its end.
  private let turning = NavigationRoute(
    line: [[0, 0], [0.01, 0], [0.01, 0.01]],
    steps: [
      NavigationStep(fromIndex: 0, toIndex: 1, maneuver: .depart),
      NavigationStep(fromIndex: 1, toIndex: 2, maneuver: .turnLeft),
      NavigationStep(fromIndex: 2, toIndex: 2, maneuver: .goal),
    ])

  private func laid() throws -> (FollowedRoute, GuidancePlan) {
    let followed = try #require(followedRouteOf(turning))
    return (followed, try #require(guidancePlanOf(followed)))
  }

  /// progress is a reading in `step` with `left` meters to its end, the rest as Geo would read it.
  private func progress(step: Int, left: Double) -> NavigationProgress {
    NavigationProgress(
      along: 0, step: step, next: step + 1,
      toManeuver: NavigationRemainder(distance: left, duration: nil),
      toArrival: NavigationRemainder(distance: left, duration: nil))
  }

  @Test(
    "before any position the first step's departure is due, as the traveller stands at its start")
  func departureFirst() throws {
    let (_, plan) = try laid()
    #expect(duePrompt(plan, progress: nil)?.instruction.key == .departPlain)
    #expect(duePrompt(plan, progress: nil)?.id == 0)
  }

  /// The rule: the distance left less the trigger is 5 m or less, the last such prompt winning.
  @Test("a prompt falls due 5 m short of its trigger, and the one nearest the maneuver wins")
  func triggerAndSlack() throws {
    let (_, plan) = try laid()
    let length = plan.steps[0].meters

    #expect(duePrompt(plan, progress: progress(step: 0, left: length))?.id == 0)
    #expect(duePrompt(plan, progress: progress(step: 0, left: 56))?.id == 0, "56 m is past 55")
    #expect(duePrompt(plan, progress: progress(step: 0, left: 55))?.id == 1, "50 m and 5 of slack")
    #expect(duePrompt(plan, progress: progress(step: 0, left: 0))?.id == 1)
    #expect(
      duePrompt(plan, progress: progress(step: 0, left: 55))?.instruction.key == .turnLeftPlain)
    #expect(duePrompt(plan, progress: progress(step: 1, left: 600)) == nil, "nothing due yet")
    #expect(duePrompt(plan, progress: progress(step: 1, left: 54))?.instruction.key == .goalPlain)
    #expect(
      duePrompt(plan, progress: progress(step: 2, left: 0)) == nil, "the arrival says nothing")
    #expect(duePrompt(plan, progress: progress(step: 0, left: .nan)) == nil, "no number, no prompt")
  }

  @Test("the step read is held within the plan")
  func stepHeld() throws {
    let (_, plan) = try laid()
    #expect(duePrompt(plan, progress: progress(step: -1, left: 40))?.id == 1)
    #expect(duePrompt(plan, progress: progress(step: 9, left: 0)) == nil)
    let empty = GuidancePlan(steps: [])
    #expect(duePrompt(empty, progress: nil) == nil)
  }

  /// The distance is Geo's own: measured from the foot on the route, never moving back.
  @Test("the distance read is Geo's progress at the position, never moving back")
  func readsGeosProgress() throws {
    let (followed, plan) = try laid()
    let before = navigationProgressAt(followed, position: [0.0096, 0.0001], previous: 0)
    #expect(duePrompt(plan, progress: before)?.id == 1, "44 m before the turn")

    // Back where the departure stood: progress holds, and the turn stays the prompt standing.
    let back = navigationProgressAt(followed, position: [0.005, 0], previous: before.along)
    #expect(back.along == before.along)
    #expect(duePrompt(plan, progress: back)?.id == 1)
  }
}
