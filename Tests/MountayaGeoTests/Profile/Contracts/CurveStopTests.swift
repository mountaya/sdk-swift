import Testing

@testable import MountayaGeo

@Suite("CurveStop")
struct CurveStopTests {
  @Test("two stops are equal where they stand at one number in one colour, or none")
  func equality() {
    #expect(CurveStop(offset: 0.2, color: nil) == CurveStop(offset: 0.2, color: nil))
    #expect(CurveStop(offset: 0.2, color: nil) != CurveStop(offset: 0.2, color: "#f00"))
    #expect(CurveStop(offset: 0, color: nil) != CurveStop(offset: -0.0, color: nil))
    #expect(
      CurveStop(offset: 0.4, color: "#f00").hashValue
        == CurveStop(offset: 0.4, color: "#f00").hashValue)
  }
}
