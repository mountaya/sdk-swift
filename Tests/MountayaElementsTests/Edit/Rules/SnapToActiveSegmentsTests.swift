import Testing

@testable import MountayaElements

@Suite("snapToActiveSegments")
@MainActor
struct SnapToActiveSegmentsTests {
  /// identity reads a longitude as an x and a latitude as a y, one degree one pixel.
  private static var identity: ScreenProjection {
    ScreenProjection(point: { $0 }, position: { $0 })
  }

  /// hundredfold draws a degree as a hundred pixels, as a map zoomed in does.
  private static var hundredfold: ScreenProjection {
    ScreenProjection(point: { $0.map { $0 * 100 } }, position: { $0.map { $0 / 100 } })
  }

  private static let line: [[Double]] = [[0, 10], [100, 10]]

  @Test("a pointer within the magnet's radius is placed on the nearest point of the line")
  func near() {
    let snap = snapToActiveSegments([50, 40], segments: [Self.line], projection: Self.identity)

    #expect(snap.position == [50, 10])
    #expect(snap.isSnapped)
  }

  @Test("the radius itself is within the magnet, and the next pixel out is not")
  func threshold() {
    #expect(
      snapToActiveSegments([50, 50], segments: [Self.line], projection: Self.identity).isSnapped)
    let past = snapToActiveSegments([50, 51], segments: [Self.line], projection: Self.identity)

    #expect(!past.isSnapped)
    #expect(past.position == [50, 51])
    #expect(snapThresholdPx == 40)
  }

  @Test("beyond an edge's end the end is nearest")
  func beyondTheEnd() {
    let snap = snapToActiveSegments([120, 10], segments: [Self.line], projection: Self.identity)

    #expect(snap.position == [100, 10])
    #expect(snap.isSnapped)
  }

  @Test("the nearest of two lines takes the point, and of two at one distance the first")
  func nearestLine() {
    let lower: [[Double]] = [[0, 10], [100, 10]]
    let upper: [[Double]] = [[0, 30], [100, 30]]

    #expect(
      snapToActiveSegments([50, 25], segments: [lower, upper], projection: Self.identity).position
        == [50, 30])
    #expect(
      snapToActiveSegments([50, 20], segments: [upper, lower], projection: Self.identity).position
        == [50, 30])
    #expect(
      snapToActiveSegments([50, 20], segments: [lower, upper], projection: Self.identity).position
        == [50, 10])
  }

  @Test("every edge of a line is read, not its first alone")
  func everyEdge() {
    let bent: [[Double]] = [[0, 0], [10, 0], [10, 100]]

    #expect(
      snapToActiveSegments([15, 60], segments: [bent], projection: Self.identity).position
        == [10, 60])
  }

  @Test("a line of one position has no edge, and no line leaves the pointer unread")
  func noEdge() {
    let alone = snapToActiveSegments([0, 15], segments: [[[0, 10]]], projection: Self.identity)
    #expect(alone.position == [0, 15])
    #expect(!alone.isSnapped)

    let untouched = ScreenProjection(
      point: { _ in
        Issue.record("the projection was read for no line")
        return [0, 0]
      },
      position: { $0 })
    #expect(
      snapToActiveSegments([50, 12], segments: [], projection: untouched).position == [50, 12])
  }

  @Test("an edge of no length is its start")
  func zeroLength() {
    let snap = snapToActiveSegments(
      [3, 4], segments: [[[0, 0], [0, 0]]], projection: Self.identity)

    #expect(snap.position == [0, 0])
    #expect(snap.isSnapped)
  }

  @Test("distances are pixels: a hundredfold projection narrows the magnet on the ground")
  func pixels() {
    let line: [[Double]] = [[10, 10], [11, 10]]

    #expect(
      snapToActiveSegments([10.5, 10.3], segments: [line], projection: Self.hundredfold).isSnapped)
    #expect(
      !snapToActiveSegments([10.5, 10.5], segments: [line], projection: Self.hundredfold).isSnapped)
  }

  @Test("a point the magnet leaves is the pointer as given; one it moves is read back")
  func altitude() {
    #expect(
      snapToActiveSegments([50, 90, 1200], segments: [Self.line], projection: Self.identity)
        .position == [50, 90, 1200])
    #expect(
      snapToActiveSegments([50, 20, 1200], segments: [Self.line], projection: Self.identity)
        .position == [50, 10])
  }

  @Test("a pointer missing a coordinate reads it as 0, and one that names no place is left")
  func placeless() {
    #expect(
      snapToActiveSegments([50], segments: [Self.line], projection: Self.identity).position
        == [50, 10])
    let nowhere = snapToActiveSegments(
      [.nan, 10], segments: [Self.line], projection: Self.identity)

    #expect(!nowhere.isSnapped)
    #expect(nowhere.position.count == 2)
  }

  @Test("a radius of the caller's own takes the magnet's place")
  func ownRadius() {
    #expect(
      !snapToActiveSegments(
        [50, 20], segments: [Self.line], projection: Self.identity, thresholdPx: 5
      )
      .isSnapped)
  }
}
