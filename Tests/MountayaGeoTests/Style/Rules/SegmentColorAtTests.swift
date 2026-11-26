import Testing

@testable import MountayaGeo

@Suite("segmentColorAt")
struct SegmentColorAtTests {
  @Test("a position reads the palette wrapped")
  func wrapped() {
    #expect(segmentColorAt(0) == "#fa5252")
    #expect(segmentColorAt(11) == "#fd7e14")
    #expect(segmentColorAt(12) == "#fa5252")
    #expect(segmentColorAt(37) == "#e64980")
    #expect(livelyPalette.count == 12)
    #expect(defaultSegmentColor == "#868e96")
  }

  @Test("a position before the first reads back from the last")
  func backwards() {
    #expect(segmentColorAt(-1) == "#fd7e14")
    #expect(segmentColorAt(-13) == "#fd7e14")
    // -2147483644, Kotlin's Int.MIN_VALUE + 4, is 8 past a whole number of turns of twelve; Swift's
    // own least Int is 4 past one, and wraps without trapping.
    #expect(segmentColorAt(-2_147_483_644) == "#40c057")
    #expect(segmentColorAt(Int.min) == "#4c6ef5")
    #expect(segmentColorAt(Int.max) == "#12b886")
  }

  /// A fraction reads the position it is past, below zero too, and a number that is none the first.
  @Test("a position that is no whole number reads the position it is past")
  func fractions() {
    #expect(segmentColorAt(2.7) == "#be4bdb")
    #expect(segmentColorAt(-0.5) == "#fd7e14")
    #expect(segmentColorAt(-0.0) == "#fa5252")
    #expect(segmentColorAt(Double.nan) == "#fa5252")
    #expect(segmentColorAt(Double.infinity) == "#fa5252")
    // 1e20 is 12 * 8333333333333333333 + 4, read exactly as the number it is, past any Int.
    #expect(segmentColorAt(1e20) == "#4c6ef5")
  }

  @Test("a palette of its own is read, and one that lists no colour reads the lively one")
  func palettes() {
    #expect(segmentColorAt(3, palette: ["#000000", "#ffffff"]) == "#ffffff")
    #expect(segmentColorAt(3, palette: []) == "#7950f2")
    #expect(segmentColorAt(3.0, palette: []) == "#7950f2")
  }
}
