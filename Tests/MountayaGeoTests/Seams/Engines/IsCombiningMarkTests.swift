import Testing

@testable import MountayaGeo

@Suite("isCombiningMark")
struct IsCombiningMarkTests {
  @Test("a mark of every kind is a combining mark")
  func marks() {
    #expect(isCombiningMark("\u{301}"), "combining acute")
    #expect(isCombiningMark("\u{93F}"), "Devanagari vowel sign i, a spacing mark")
    #expect(isCombiningMark("\u{64E}"), "Arabic fatha")
    #expect(isCombiningMark("\u{20DD}"), "combining enclosing circle")
    #expect(isCombiningMark("\u{1D165}"), "musical symbol combining stem, beyond the basic plane")
  }

  @Test("a letter, a digit and a joiner are no combining mark")
  func others() {
    #expect(!isCombiningMark("e"))
    #expect(!isCombiningMark("7"))
    #expect(!isCombiningMark("\u{915}"), "Devanagari ka")
    #expect(!isCombiningMark("\u{200D}"), "zero width joiner")
    #expect(!isCombiningMark("\u{1F600}"), "an emoji")
  }
}
