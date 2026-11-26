import Testing

@testable import MountayaGeo

@Suite("PixelPadding")
struct PixelPaddingTests {
  @Test("one number is the padding of every edge")
  func uniform() {
    #expect(PixelPadding(100) == PixelPadding(top: 100, right: 100, bottom: 100, left: 100))
    #expect(
      PixelPadding(100).hashValue
        == PixelPadding(top: 100, right: 100, bottom: 100, left: 100).hashValue)
  }

  @Test("each edge is named by its side")
  func sides() {
    let padding = PixelPadding(top: 56, right: 57, bottom: 250, left: 58)
    #expect([padding.top, padding.right, padding.bottom, padding.left] == [56, 57, 250, 58])
    #expect(
      String(describing: padding)
        == "PixelPadding(top: 56.0, right: 57.0, bottom: 250.0, left: 58.0)")
    #expect(padding != PixelPadding(top: 250, right: 57, bottom: 56, left: 58))
  }

  @Test("two paddings compare their numbers as the same numbers")
  func sameNumbers() {
    #expect(PixelPadding(.nan) == PixelPadding(.nan))
    #expect(PixelPadding(.nan).hashValue == PixelPadding(.nan).hashValue)
    #expect(PixelPadding(0) != PixelPadding(-0.0))
  }
}
