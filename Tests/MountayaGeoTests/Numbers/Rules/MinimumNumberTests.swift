import Testing

@testable import MountayaGeo

@Suite("minimumNumber")
struct MinimumNumberTests {
  @Test("the lesser number is the answer, whichever side it is written on")
  func lesser() {
    #expect(minimumNumber(3, 5) == 3)
    #expect(minimumNumber(5, 3) == 3)
    #expect(minimumNumber(-.infinity, 5) == -.infinity)
  }

  @Test("NaN on either side is NaN, where the standard library's min answers the other side")
  func notANumber() {
    #expect(minimumNumber(.nan, 3).isNaN)
    #expect(minimumNumber(3, .nan).isNaN)
  }

  @Test("of the two zeros, -0 is the lesser")
  func zeros() {
    #expect(minimumNumber(0, -0.0).sign == .minus)
    #expect(minimumNumber(-0.0, 0).sign == .minus)
  }
}
