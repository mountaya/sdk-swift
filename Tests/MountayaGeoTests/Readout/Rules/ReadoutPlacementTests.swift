import Testing

@testable import MountayaGeo

@Suite("readoutPlacement")
struct ReadoutPlacementTests {
  /// mark is the watermark's frame on a map whose safe area starts 59 points down.
  private let mark = ScreenRect(x: -4, y: 55, width: 180, height: 75.5)
  /// safe is that map's safe area, on a phone held upright.
  private let safe = ScreenRect(x: 0, y: 59, width: 390, height: 751)

  @Test("the card stands with its top-left corner at its point")
  func atThePoint() {
    #expect(
      readoutPlacement(at: [60, 400], cardHeight: 160, within: safe, clearOf: mark)
        == ScreenRect(x: 60, y: 400, width: 288, height: 160))
  }

  @Test("it flips to the left of its point and above it where it would leave the safe area")
  func flipped() {
    let right = readoutPlacement(at: [300, 400], cardHeight: 160, within: safe, clearOf: nil)
    #expect(right.x == 300 - 288 && right.y == 400)
    let low = readoutPlacement(at: [60, 760], cardHeight: 160, within: safe, clearOf: nil)
    #expect(low.x == 60 && low.y == 760 - 160)
    let both = readoutPlacement(at: [300, 760], cardHeight: 160, within: safe, clearOf: nil)
    #expect(both == ScreenRect(x: 12, y: 600, width: 288, height: 160))
  }

  @Test("a flip that would leave the safe area is held inside it")
  func held() {
    let placed = readoutPlacement(at: [200, 300], cardHeight: 700, within: safe, clearOf: nil)
    #expect(placed == ScreenRect(x: 0, y: 59, width: 288, height: 700))
  }

  @Test("a card that would lay over the watermark moves clear of it by the smallest move")
  func clear() {
    let placed = readoutPlacement(at: [20, 100], cardHeight: 160, within: safe, clearOf: mark)
    #expect(placed.y == mark.maxY && placed.x == 20)
    #expect(!placed.overlaps(mark))
  }

  @Test("where nothing inside the safe area clears the frame, its top is at the frame's bottom")
  func cut() {
    let short = ScreenRect(x: 0, y: 59, width: 390, height: 120)
    let placed = readoutPlacement(at: [20, 70], cardHeight: 160, within: short, clearOf: mark)
    #expect(placed.y == mark.maxY && !placed.overlaps(mark))
  }

  @Test("a point that names no place stands it at the safe area's corner, clear of the frame")
  func nowhere() {
    let placed = readoutPlacement(at: [], cardHeight: 160, within: safe, clearOf: mark)
    #expect(placed.x == 0 && placed.y == mark.maxY)
    #expect(
      readoutPlacement(at: [.nan, 10], cardHeight: 160, within: safe, clearOf: nil)
        == ScreenRect(x: 0, y: 59, width: 288, height: 160))
  }
}
