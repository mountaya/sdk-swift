import Testing

@testable import MountayaGeo

@Suite("SearchPause")
struct SearchPauseTests {
  /// A pause is a length of time, and one below zero is a search set up wrong: it is refused as the
  /// search is built, as a cap outside 1 to 50 is (`geo.search.typing-pause`).
  @Test("a pause below zero is no pause a search is built with, and zero or more is one")
  func belowZero() {
    #expect(SearchPause(.milliseconds(-1)) == nil)
    #expect(SearchPause(.nanoseconds(-1)) == nil)
    #expect(SearchPause(.zero)?.duration == .zero)
    #expect(SearchPause(.milliseconds(150))?.duration == .milliseconds(150))
  }

  @Test("the standard pause is the typing pause a search is given where it is given none")
  func standard() {
    #expect(SearchPause.standard.duration == searchTypingPause)
    #expect(SearchPause.standard == SearchPause(.milliseconds(150)))
  }
}
