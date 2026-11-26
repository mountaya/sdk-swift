import Testing

@testable import MountayaGeo

@Suite("distanceToSegment")
struct DistanceToSegmentTests {
  private let start: [Double] = [6.8652, 45.9237]
  private let end: [Double] = [6.9271, 45.9682]

  /// In degrees as written, with no cosine: the fixture's cases answer that, and it is not meters.
  @Test("the distance is planar in the degrees the positions are written in")
  func planar() {
    #expect(distanceToSegment(start, start: start, end: end) == 0)
    #expect(
      isClose(
        distanceToSegment([6.9, 45.9], start: start, end: end), 0.039556739110611465, within: 1e-15)
    )
    #expect(distanceToSegment([3, 4], start: [0, 0], end: [0, 0]) == 5)
  }

  @Test("a point past an end is measured to that end")
  func pastAnEnd() {
    #expect(
      isClose(
        distanceToSegment([7, 46], start: start, end: end), 0.07953395501293625, within: 1e-15))
    #expect(distanceToSegment([-1, 0], start: [0, 0], end: [4, 0]) == 1)
  }

  @Test("a degenerate segment answers the distance to its one vertex")
  func degenerate() {
    #expect(
      isClose(distanceToSegment(end, start: start, end: start), 0.07623555600899513, within: 1e-15))
  }

  /// A plane has no antimeridian: these two are 359.8 degrees apart as written.
  @Test("nothing is wrapped")
  func nothingWrapped() {
    #expect(
      isClose(
        distanceToSegment([179.9, 0], start: [-179.9, 0], end: [-179.9, 0]), 359.8, within: 1e-12))
  }

  @Test("a position that names no place answers NaN")
  func noPlace() {
    #expect(distanceToSegment([7], start: start, end: end).isNaN)
    #expect(distanceToSegment([7, 46], start: [.nan, 45], end: end).isNaN)
    #expect(distanceToSegment([7, 46], start: start, end: []).isNaN)
  }

  @Test("the fraction along a segment keeps NaN rather than reading it as an end")
  func fractionKeepsNaN() {
    #expect(
      planarDistanceToSegment(pointX: .nan, pointY: 0, startX: 0, startY: 0, endX: 1, endY: 0).isNaN
    )
    #expect(
      planarFootFraction(pointX: .nan, pointY: 0, startX: 0, startY: 0, endX: 1, endY: 0).isNaN)
  }

  /// The one projection both the distance and a traveller's progress stand on.
  @Test("the foot is the projection clamped to the segment's ends")
  func foot() {
    #expect(
      planarFootFraction(pointX: 1, pointY: 3, startX: 0, startY: 0, endX: 4, endY: 0) == 0.25)
    #expect(planarFootFraction(pointX: -1, pointY: 0, startX: 0, startY: 0, endX: 4, endY: 0) == 0)
    #expect(planarFootFraction(pointX: 9, pointY: 1, startX: 0, startY: 0, endX: 4, endY: 0) == 1)
    #expect(planarFootFraction(pointX: 3, pointY: 4, startX: 2, startY: 2, endX: 2, endY: 2) == 0)
    #expect(
      planarDistanceToFoot(
        pointX: 1, pointY: 3, startX: 0, startY: 0, endX: 4, endY: 0, fraction: 0.25) == 3)
    #expect(
      planarDistanceToSegment(pointX: 7, pointY: 4, startX: 0, startY: 0, endX: 4, endY: 0) == 5)
  }
}
