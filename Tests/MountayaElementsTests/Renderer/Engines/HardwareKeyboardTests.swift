import GameController
import Testing

@testable import MountayaElements

@Suite("HardwareKeyboard")
@MainActor
struct HardwareKeyboardTests {
  @Test("a hardware keyboard is at hand where the platform has a keyboard connected")
  func connected() {
    #expect(HardwareKeyboard.isConnected == (GCKeyboard.coalesced != nil))
  }
}
