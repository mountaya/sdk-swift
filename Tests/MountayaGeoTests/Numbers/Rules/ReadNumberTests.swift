import Testing

@testable import MountayaGeo

@Suite("readNumber")
struct ReadNumberTests {
  @Test("a decimal literal is its value, the white space at its ends left out")
  func decimal() {
    #expect(readNumber("3600") == 3_600)
    #expect(readNumber(" 1234.56789\n") == 1_234.56789)
    #expect(readNumber("+1.5e3") == 1_500 && readNumber("-2") == -2)
    #expect(readNumber(".5") == 0.5 && readNumber("5.") == 5 && readNumber("1E-2") == 0.01)
  }

  @Test(
    "the empty text is zero, and the infinities and prefixed literals read as ECMAScript reads them"
  )
  func ecmascript() {
    #expect(readNumber("") == 0 && readNumber("  ") == 0)
    #expect(readNumber("Infinity") == .infinity && readNumber("-Infinity") == -.infinity)
    #expect(readNumber("0x10") == 16 && readNumber("0o17") == 15 && readNumber("0B101") == 5)
  }

  @Test("anything else is no number")
  func notNumbers() {
    for text in [
      "abc", "1_000", "0x1p3", "nan", "inf", "-0x10", "1e", ".", "+", "0xG", "1 2", "١٢",
    ] {
      #expect(readNumber(text).isNaN, "\(text)")
    }
  }
}
