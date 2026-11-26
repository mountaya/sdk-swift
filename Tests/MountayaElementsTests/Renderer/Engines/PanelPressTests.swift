import Testing

@testable import MountayaElements

@Suite("PanelPress")
@MainActor
struct PanelPressTests {
  /// A row SwiftUI keeps as it was drawn holds the press of the panel it was drawn in, which the
  /// panel drawn since answers for.
  @Test(
    "a press is answered by what the panel drawn last holds, and by nothing before it holds any")
  func answeredByTheLatest() {
    let press = PanelPress<String>()
    var answered: [String] = []

    press.press("unheld")
    press.hold { answered.append("first " + $0) }
    press.press("a")
    press.hold { answered.append("second " + $0) }
    press.press("b")

    #expect(answered == ["first a", "second b"])
  }
}
