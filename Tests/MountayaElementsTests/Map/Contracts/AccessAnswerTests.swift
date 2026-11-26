import Testing

@testable import MountayaElements

@Suite("AccessAnswer")
struct AccessAnswerTests {
  @Test("a refusal names its source or none, a tile its source, a style nothing")
  func answers() {
    #expect(AccessAnswer.refused(source: nil) != .refused(source: "slope"))
    #expect(AccessAnswer.tile(source: "slope") != .refused(source: "slope"))
    #expect(AccessAnswer.style == .style)
  }
}
