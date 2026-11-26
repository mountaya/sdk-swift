import Testing

@testable import MountayaGeo

@Suite("canonicalComposition")
struct CanonicalCompositionTests {
  @Test("a base and the marks that compose with it are one letter")
  func composed() {
    #expect(scalars(canonicalComposition("E\u{301}vian")) == scalars("\u{C9}vian"))
    #expect(scalars(canonicalComposition("\u{1100}\u{1161}")) == [0xAC00])
    #expect(scalars(canonicalComposition("\u{30AB}\u{3099}")) == [0x30AC])
  }

  /// A mark that composes with nothing is kept beside its base.
  @Test("a mark that composes with nothing is kept")
  func kept() {
    #expect(scalars(canonicalComposition("q\u{301}")) == [0x71, 0x301])
  }

  /// The trap the fold steers clear of: `==` calls a text and its composition one text.
  @Test("a text and its composition are one String to ==, and two to their scalars")
  func comparedByScalars() {
    #expect(canonicalComposition("E\u{301}") == "E\u{301}")
    #expect(scalars(canonicalComposition("E\u{301}")) != scalars("E\u{301}"))
  }
}
