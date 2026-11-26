import Testing

@testable import MountayaGeo

@Suite("firstPlace")
struct FirstPlaceTests {
  private func scalarArray(_ text: String) -> [Unicode.Scalar] { Array(text.unicodeScalars) }

  @Test("the first run of the pattern at or after the place asked is found")
  func found() {
    #expect(
      firstPlace(of: scalarArray("de"), in: scalarArray("Col de la Croix de Fer"), from: 0) == 4)
    #expect(
      firstPlace(of: scalarArray("de"), in: scalarArray("Col de la Croix de Fer"), from: 5) == 16)
    #expect(firstPlace(of: scalarArray("x"), in: scalarArray("abc"), from: 0) == nil)
    #expect(firstPlace(of: scalarArray("abc"), in: scalarArray("ab"), from: 0) == nil)
    #expect(firstPlace(of: scalarArray("a"), in: scalarArray("a"), from: 2) == nil)
    #expect(firstPlace(of: [], in: scalarArray("a"), from: 0) == nil)
  }

  /// A precomposed letter is one scalar, so a plain `e` is never found inside it.
  @Test("a pattern is compared scalar by scalar")
  func scalarByScalar() {
    #expect(firstPlace(of: scalarArray("e"), in: scalarArray("\u{E9}"), from: 0) == nil)
    #expect(firstPlace(of: scalarArray("e"), in: scalarArray("e\u{301}"), from: 0) == 0)
  }
}
