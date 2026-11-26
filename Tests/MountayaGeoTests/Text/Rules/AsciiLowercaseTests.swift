import Testing

@testable import MountayaGeo

@Suite("asciiLowercase")
struct AsciiLowercaseTests {
  @Test("only the ASCII capitals are folded")
  func folding() {
    #expect(asciiLowercase("#3B82F6") == "#3b82f6")
    #expect(asciiLowercase("CurrentColor") == "currentcolor")
    #expect(asciiLowercase("İSTANBUL é") == "İstanbul é")
    #expect(asciiLowercase("ß") == "ß")
  }

  @Test("a text with no capital is answered as it is")
  func unchanged() {
    #expect(asciiLowercase("already small") == "already small")
  }
}
