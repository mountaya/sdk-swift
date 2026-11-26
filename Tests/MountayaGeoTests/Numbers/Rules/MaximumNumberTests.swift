import Testing

@testable import MountayaGeo

@Suite("maximumNumber")
struct MaximumNumberTests {
  @Test("the greater number is the answer, whichever side it is written on")
  func greater() {
    #expect(maximumNumber(3, 5) == 5)
    #expect(maximumNumber(5, 3) == 5)
    #expect(maximumNumber(.infinity, 5) == .infinity)
  }

  @Test("NaN on either side is NaN, where the standard library's max answers the other side")
  func notANumber() {
    #expect(maximumNumber(.nan, 3).isNaN)
    #expect(maximumNumber(3, .nan).isNaN)
  }

  @Test("of the two zeros, 0 is the greater")
  func zeros() {
    #expect(maximumNumber(0, -0.0).sign == .plus)
    #expect(maximumNumber(-0.0, 0).sign == .plus)
  }
}
