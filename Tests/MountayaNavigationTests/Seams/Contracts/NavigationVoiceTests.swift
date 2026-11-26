import MountayaClient
import MountayaGeo
import Testing

@testable import MountayaNavigation

@Suite("NavigationVoice")
@MainActor
struct NavigationVoiceTests {
  @Test("a voice is handed an instruction as a key and its arguments, never a sentence")
  func instructionsAreKeys() {
    let voice = RecordingVoice()
    let step = NavigationStep(
      fromIndex: 0, toIndex: 1, maneuver: .turnLeft, name: "Rue")
    let instruction = stepInstruction(step)

    voice.say(instruction)
    voice.hush()

    #expect(voice.said.map(\.key) == [.turnLeft])
    #expect(voice.said.first?.name == "Rue")
    #expect(voice.hushed == 1)
  }
}
