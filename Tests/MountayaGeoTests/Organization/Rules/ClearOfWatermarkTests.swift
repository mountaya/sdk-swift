import Testing

@testable import MountayaGeo

@Suite("clearOfWatermark")
struct ClearOfWatermarkTests {
  private let mark = ScreenRect(x: -4, y: -4, width: 180, height: 75.5)
  private let phone = ScreenRect(x: 0, y: 0, width: 390, height: 844)

  @Test("a tall box in the top-left corner moves down, its top at the frame's bottom")
  func under() {
    let stack = ScreenRect(x: 10, y: 10, width: 44, height: 200)
    #expect(
      clearOfWatermark(stack, frame: mark, within: phone)
        == ScreenRect(x: 10, y: 71.5, width: 44, height: 200))
  }

  @Test("the smallest move wins: a box low on the frame moves down, one at its right edge right")
  func smallest() {
    let low = ScreenRect(x: 20, y: 60, width: 100, height: 40)
    #expect(clearOfWatermark(low, frame: mark, within: phone).y == 71.5)
    let edge = ScreenRect(x: 170, y: 10, width: 100, height: 40)
    #expect(
      clearOfWatermark(edge, frame: mark, within: phone)
        == ScreenRect(x: 176, y: 10, width: 100, height: 40))
  }

  @Test("on a short map, a box that cannot clear the frame below it stands beside it")
  func beside() {
    let short = ScreenRect(x: 0, y: 0, width: 844, height: 120)
    let card = ScreenRect(x: 20, y: 10, width: 288, height: 100)
    #expect(clearOfWatermark(card, frame: mark, within: short).x == mark.maxX)
  }

  @Test(
    "where no place inside the safe area clears the frame, its top stands at the frame's bottom")
  func cut() {
    let tiny = ScreenRect(x: 0, y: 0, width: 300, height: 120)
    let card = ScreenRect(x: 0, y: 0, width: 288, height: 100)
    let kept = clearOfWatermark(card, frame: mark, within: tiny)
    #expect(kept.y == mark.maxY && kept.maxY > tiny.maxY, "the map's edge cuts it")
    #expect(!kept.overlaps(mark))
  }

  @Test("what shares no area with the frame, or a map drawing no mark, stands where it is")
  func untouched() {
    let stack = ScreenRect(x: 336, y: 10, width: 44, height: 200)
    #expect(clearOfWatermark(stack, frame: mark, within: phone) == stack)
    let corner = ScreenRect(x: 10, y: 10, width: 44, height: 44)
    #expect(clearOfWatermark(corner, frame: nil, within: phone) == corner)
  }
}
