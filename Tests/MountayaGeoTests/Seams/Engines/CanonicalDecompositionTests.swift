import Testing

@testable import MountayaGeo

@Suite("canonicalDecomposition")
struct CanonicalDecompositionTests {
  @Test("a composed letter is written as its base and its marks")
  func decomposed() {
    #expect(scalars(canonicalDecomposition("\u{C9}vian")) == scalars("E\u{301}vian"))
    #expect(scalars(canonicalDecomposition("\u{1EB5}")) == scalars("a\u{306}\u{303}"))
    #expect(scalars(canonicalDecomposition("\u{AC00}")) == scalars("\u{1100}\u{1161}"))
    #expect(scalars(canonicalDecomposition("plain")) == scalars("plain"))
  }

  /// A stroke is no mark: nothing decomposes it.
  @Test("a letter with a stroke has no decomposition")
  func stroke() {
    #expect(scalars(canonicalDecomposition("\u{142}")) == [0x142])
    #expect(scalars(canonicalDecomposition("\u{DF}")) == [0xDF])
  }
}
