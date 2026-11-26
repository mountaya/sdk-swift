import Testing

@testable import MountayaGeo

@Suite("CurveColor")
struct CurveColorTests {
  @Test("two stretches are equal where both ends are the same numbers and the colours alike")
  func equality() {
    let stretch = CurveColor(from: 200, to: 400, color: "#f00")
    #expect(stretch == CurveColor(from: 200, to: 400, color: "#f00"))
    #expect(stretch.hashValue == CurveColor(from: 200, to: 400, color: "#f00").hashValue)
    #expect(stretch != CurveColor(from: 200, to: 400, color: "#F00"))
    #expect(
      CurveColor(from: 0, to: 1, color: "\u{E9}") == CurveColor(from: 0, to: 1, color: "\u{E9}"))
    #expect(
      CurveColor(from: 0, to: 1, color: "\u{E9}") != CurveColor(from: 0, to: 1, color: "e\u{301}"))
  }
}
