import Testing

@testable import MountayaElements

@Suite("ControlMove")
struct ControlMoveTests {
  @Test("each move is spelled as the contract spells it")
  func spellings() {
    #expect(ControlMove.allCases.map(\.rawValue) == ["zoom-in", "zoom-out", "reset-north"])
  }
}
