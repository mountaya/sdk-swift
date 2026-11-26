import Testing

@testable import MountayaGeo

@Suite("parsePaceClock")
struct ParsePaceClockTests {
  @Test("a clock or a bare number of minutes is read")
  func read() {
    #expect(parsePaceClock("13:20") == 13.333333333333334)
    #expect(parsePaceClock("4:05") == 4.083333333333333)
    #expect(parsePaceClock("13") == 13)
    #expect(parsePaceClock("6,5") == 6.5)
    #expect(parsePaceClock("6.5") == 6.5)
    #expect(parsePaceClock("  7:45 ") == 7.75)
  }

  /// An Arabic-Indic or a fullwidth digit is a digit to `Character.isNumber`, and no ASCII one.
  @Test("anything else is no pace")
  func anythingElse() {
    for text in [
      "13:5", "13:60", "1:02:03", "0:00", "0", "fast", "", "-4", "+4", "4.", ".5", "4:05 min",
      "4 :05", "4\u{A0}:05", "\u{664}:\u{660}\u{665}", "\u{FF14}", "4:\u{FF10}5",
    ] {
      #expect(parsePaceClock(text) == nil, "`\(text)`")
    }
  }
}
