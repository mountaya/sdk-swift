import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("GuidancePrompt")
struct GuidancePromptTests {
  private let left = stepInstruction(
    NavigationStep(fromIndex: 0, toIndex: 1, maneuver: .turnLeft))

  @Test("two prompts are equal where they hold one place, one instruction and one distance")
  func equality() {
    #expect(
      GuidancePrompt(id: 1, instruction: left, meters: 50)
        == GuidancePrompt(id: 1, instruction: left, meters: 50))
    #expect(
      GuidancePrompt(id: 1, instruction: left, meters: 50)
        != GuidancePrompt(id: 2, instruction: left, meters: 50))
    #expect(
      GuidancePrompt(id: 1, instruction: left, meters: 50)
        != GuidancePrompt(id: 1, instruction: left, meters: 40))
  }
}
