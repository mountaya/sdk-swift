import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("GuidanceStep")
struct GuidanceStepTests {
  private let depart = stepInstruction(
    NavigationStep(fromIndex: 0, toIndex: 1, maneuver: .depart))
  private let left = stepInstruction(
    NavigationStep(fromIndex: 0, toIndex: 1, maneuver: .turnLeft))

  @Test("two steps are equal where every member is")
  func equality() {
    let step = GuidanceStep(meters: 1_112, instruction: depart, prompts: [])
    #expect(step == GuidanceStep(meters: 1_112, instruction: depart, prompts: []))
    #expect(step != GuidanceStep(meters: 1_000, instruction: depart, prompts: []))
    #expect(step != GuidanceStep(meters: 1_112, instruction: left, prompts: []))
    #expect(
      step
        != GuidanceStep(
          meters: 1_112, instruction: depart,
          prompts: [GuidancePrompt(id: 0, instruction: depart, meters: 1_112)]))
  }
}
