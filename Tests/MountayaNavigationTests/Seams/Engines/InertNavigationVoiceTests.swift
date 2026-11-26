import MountayaClient
import MountayaGeo
import Testing

@testable import MountayaNavigation

@Suite("InertNavigationVoice")
@MainActor
struct InertNavigationVoiceTests {
  @Test("an inert voice takes every instruction and every hush, in any order, and says nothing")
  func saysNothing() {
    let voice: any NavigationVoice = InertNavigationVoice()
    let step = NavigationStep(fromIndex: 0, toIndex: 0, maneuver: .goal)

    voice.hush()
    voice.say(stepInstruction(step))
    voice.hush()
    voice.say(stepInstruction(step))
  }
}
