import Testing

@testable import MountayaGeo

@Suite("ScreenRect")
struct ScreenRectTests {
  @Test("two rectangles overlap where they share area, never where their edges only touch")
  func overlaps() {
    let mark = ScreenRect(x: -4, y: -4, width: 180, height: 75.5)
    #expect(mark.maxX == 176 && mark.maxY == 71.5)
    #expect(mark.overlaps(ScreenRect(x: 10, y: 10, width: 44, height: 44)))
    #expect(!mark.overlaps(ScreenRect(x: 176, y: 10, width: 44, height: 44)))
    #expect(!mark.overlaps(ScreenRect(x: 10, y: 71.5, width: 44, height: 44)))
    #expect(mark.offset(dx: 4, dy: 59) == ScreenRect(x: 0, y: 55, width: 180, height: 75.5))
  }

  @Test("two rectangles are equal where every number is the same, NaN the same as NaN")
  func equality() {
    let nan = ScreenRect(x: .nan, y: 0, width: 1, height: 1)
    #expect(nan == nan)
    #expect(Set([nan, nan]).count == 1)
    #expect(
      ScreenRect(x: 0, y: 0, width: 1, height: 1) != ScreenRect(x: -0.0, y: 0, width: 1, height: 1))
  }
}
