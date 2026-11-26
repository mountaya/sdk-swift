import Testing

@testable import MountayaGeo

@Suite("trimWhiteSpace")
struct TrimWhiteSpaceTests {
  @Test("the white space at each end is removed and the rest kept")
  func trimming() {
    #expect(trimWhiteSpace("  7:45 ") == "7:45")
    #expect(trimWhiteSpace("\t\n a b\r\n") == "a b")
    #expect(trimWhiteSpace("\u{FEFF} x\u{3000} ") == "x")
    #expect(trimWhiteSpace("   ") == "")
    #expect(trimWhiteSpace("plain") == "plain")
  }

  /// Foundation's whitespacesAndNewlines holds the next line control and not the byte order mark,
  /// and a carriage return and a line feed are one Character but two scalars.
  @Test("the set is written out, scalar by scalar")
  func theSet() {
    for scalar: Unicode.Scalar in [
      "\u{0B}", "\u{0C}", "\u{A0}", "\u{2000}", "\u{200A}", "\u{202F}", "\u{205F}", "\u{1680}",
      "\u{2028}", "\u{2029}",
    ] {
      #expect(isWhiteSpace(scalar), "U+\(String(scalar.value, radix: 16))")
    }
    for scalar: Unicode.Scalar in ["\u{85}", "\u{200B}", "\u{180E}", "a", "\u{0}"] {
      #expect(!isWhiteSpace(scalar), "U+\(String(scalar.value, radix: 16))")
    }
    #expect(trimWhiteSpace("\u{85}x\u{85}") == "\u{85}x\u{85}")
    #expect(trimWhiteSpace("x\r\n") == "x")
  }
}
