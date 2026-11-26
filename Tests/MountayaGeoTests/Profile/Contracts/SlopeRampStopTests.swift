import Testing

@testable import MountayaGeo

@Suite("SlopeRampStop")
struct SlopeRampStopTests {
  @Test("two stops are equal when they hold the same colour and degrees, and hash alike")
  func equality() {
    #expect(
      SlopeRampStop(color: "#66BB6A", degrees: 2) == SlopeRampStop(color: "#66BB6A", degrees: 2))
    #expect(
      SlopeRampStop(color: "#66BB6A", degrees: 2).hashValue
        == SlopeRampStop(color: "#66BB6A", degrees: 2).hashValue)
    #expect(
      SlopeRampStop(color: "#66BB6A", degrees: 2) != SlopeRampStop(color: "#66bb6a", degrees: 2))
    #expect(
      SlopeRampStop(color: "#66BB6A", degrees: 0) != SlopeRampStop(color: "#66BB6A", degrees: -0.0))
    #expect(
      String(describing: SlopeRampStop(color: "#66BB6A", degrees: 2))
        == "SlopeRampStop(color: \"#66BB6A\", degrees: 2.0)")
  }

  @Test("two stops are told apart by the scalars of their colours")
  func scalars() {
    #expect(
      SlopeRampStop(color: "\u{E9}", degrees: 2) != SlopeRampStop(color: "e\u{301}", degrees: 2))
  }
}
