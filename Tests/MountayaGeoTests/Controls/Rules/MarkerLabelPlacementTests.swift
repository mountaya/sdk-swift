import Testing

@testable import MountayaGeo

@Suite("markerLabelPlacement")
struct MarkerLabelPlacementTests {
  /// mark is the watermark's frame on a map whose safe area starts 59 points down.
  private let mark = ScreenRect(x: -4, y: 55, width: 180, height: 75.5)
  /// phone is a phone's map drawn full bleed, its safe area under the status bar and above the
  /// home indicator.
  private let phone = ScreenRect(x: 0, y: 59, width: 390, height: 751)

  @Test("the label starts past the pin toward the end its text runs to, centred on the point")
  func beside() throws {
    let right = try #require(
      markerLabelPlacement(
        at: [200, 400], width: 80, height: 24, isRightToLeft: false, within: phone, clearOf: mark))
    #expect(right == ScreenRect(x: 218, y: 388, width: 80, height: 24))
    let left = try #require(
      markerLabelPlacement(
        at: [200, 400], width: 80, height: 24, isRightToLeft: true, within: phone, clearOf: mark))
    #expect(left == ScreenRect(x: 102, y: 388, width: 80, height: 24))
  }

  @Test("the label keeps to the safe area, never under the status bar or past the map's edge")
  func inside() throws {
    let edge = try #require(
      markerLabelPlacement(
        at: [370, 600], width: 80, height: 24, isRightToLeft: false, within: phone, clearOf: nil))
    #expect(edge.maxX == phone.maxX)
    let top = try #require(
      markerLabelPlacement(
        at: [300, 40], width: 80, height: 24, isRightToLeft: false, within: phone, clearOf: nil))
    #expect(top.y == phone.y, "below the status bar a full-bleed map spans")
  }

  @Test("a label that would lay over the watermark moves clear of it by the smallest move")
  func clearOfTheMark() throws {
    let low = try #require(
      markerLabelPlacement(
        at: [60, 120], width: 80, height: 24, isRightToLeft: false, within: phone, clearOf: mark))
    #expect(low == ScreenRect(x: 78, y: mark.maxY, width: 80, height: 24), "down, the shorter")
    let edge = try #require(
      markerLabelPlacement(
        at: [150, 80], width: 80, height: 24, isRightToLeft: false, within: phone, clearOf: mark))
    #expect(edge.x == mark.maxX && edge.y == 68, "right, the shorter")
    #expect(!low.overlaps(mark) && !edge.overlaps(mark))
    let white = try #require(
      markerLabelPlacement(
        at: [60, 120], width: 80, height: 24, isRightToLeft: false, within: phone, clearOf: nil))
    #expect(white.y == 108, "a map drawing no mark leaves it beside its point")
  }

  @Test("a point that names no place places no label")
  func nowhere() {
    #expect(
      markerLabelPlacement(
        at: [.nan, 10], width: 80, height: 24, isRightToLeft: false, within: phone, clearOf: mark)
        == nil)
    #expect(
      markerLabelPlacement(
        at: [10], width: 80, height: 24, isRightToLeft: false, within: phone, clearOf: mark) == nil)
  }
}
