import Testing

@testable import MountayaGeo

@Suite("clampNumber")
struct ClampNumberTests {
  @Test("a number is held within the range, and one inside it is itself")
  func held() {
    #expect(clampNumber(-1, to: 0...1) == 0)
    #expect(clampNumber(2, to: 0...1) == 1)
    #expect(clampNumber(0.25, to: 0...1) == 0.25)
    #expect(clampNumber(-.infinity, to: 0...1) == 0)
  }

  @Test("NaN stays NaN, where min and max would read it as a bound")
  func notANumber() {
    #expect(clampNumber(.nan, to: 0...1).isNaN)
  }
}
