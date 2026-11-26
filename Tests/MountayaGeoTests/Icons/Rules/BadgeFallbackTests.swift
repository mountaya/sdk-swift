import Testing

@testable import MountayaGeo

@Suite("badgeFallback")
struct BadgeFallbackTests {
  @Test("a badge filling a table cell is written as the amenity's name, as given")
  func cell() {
    #expect(badgeFallback("Drop bag", on: .cell) == "Drop bag")
    #expect(badgeFallback(" eau ", on: .cell) == " eau ")
    #expect(badgeFallback("", on: .cell) == "")
  }

  @Test("a badge beside a label of its own is drawn as nothing")
  func labelled() {
    #expect(badgeFallback("Drop bag", on: .labelled) == nil)
  }

  @Test("a badge in a profile's stack is the name's first letter, in capitals")
  func stack() {
    #expect(badgeFallback("Drop bag", on: .stack) == "D")
    #expect(badgeFallback("eau potable", on: .stack) == "E")
    #expect(badgeFallback("ß", on: .stack) == "SS")
    #expect(badgeFallback("ǆ", on: .stack) == "Ǆ")
    #expect(badgeFallback("", on: .stack) == "")
  }

  /// The first character a reader sees is an extended grapheme cluster, never a scalar.
  @Test("the first letter is the first grapheme cluster, its marks and an emoji kept whole")
  func graphemes() {
    #expect(badgeFallback("e\u{301}tape", on: .stack) == "E\u{301}")
    #expect(badgeFallback("🚰 Water", on: .stack) == "🚰")
    #expect(badgeFallback("🇫🇷 Refuge", on: .stack) == "🇫🇷")
    #expect(badgeFallback("👨‍👩‍👧 Famille", on: .stack) == "👨‍👩‍👧")
    #expect(badgeFallback("\r\nhut", on: .stack) == "\r\n")
    #expect(badgeFallback("ᄀ\u{1161}\u{11A8}", on: .stack) == "ᄀ\u{1161}\u{11A8}")
  }
}
