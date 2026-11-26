import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("GuidancePlan")
struct GuidancePlanTests {
  private let depart = stepInstruction(
    NavigationStep(fromIndex: 0, toIndex: 1, maneuver: .depart))
  private let arrive = stepInstruction(
    NavigationStep(fromIndex: 1, toIndex: 1, maneuver: .goal))

  /// plan is a plan of one step that departs and announces the arrival `arriving` meters before
  /// its end, then the arrival's own step.
  private func plan(arriving: Double = 50) -> GuidancePlan {
    GuidancePlan(
      steps: [
        GuidanceStep(
          meters: 100, instruction: depart,
          prompts: [
            GuidancePrompt(id: 0, instruction: depart, meters: 100),
            GuidancePrompt(id: 1, instruction: arrive, meters: arriving),
          ]),
        GuidanceStep(meters: 0, instruction: arrive, prompts: []),
      ])
  }

  @Test("two plans are equal where every step is, each step's prompts among them")
  func equality() {
    #expect(plan() == plan())
    #expect(plan() != plan(arriving: 40))
    #expect(plan() != GuidancePlan(steps: Array(plan().steps.prefix(1))))
    #expect(plan().steps.flatMap(\.prompts).map(\.id) == [0, 1])
  }
}
