import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("metersToRoute")
struct MetersToRouteTests {
  private let straight = GeoJSONLineString(coordinates: [[6.86, 45.85], [6.9, 45.85]])

  private func line(_ positions: [Double]...) -> GeoJSONLineString {
    GeoJSONLineString(coordinates: positions)
  }

  @Test("a point beside the line is its distance in the local plane")
  func beside() {
    #expect(
      isClose(metersToRoute([6.88, 45.851], lines: [straight]), 111.1949266442996, within: 1e-9))
    #expect(metersToRoute([6.88, 45.85], lines: [straight]) == 0)
    #expect(
      isClose(metersToRoute([6.95, 45.85], lines: [straight]), 3_872.581345548356, within: 1e-9))
  }

  @Test("the nearest segment of any line is the distance")
  func nearest() {
    let far = line([6.86, 45.9], [6.9, 45.9])
    let near = line([6.88, 45.8505], [6.89, 45.8505])
    #expect(
      isClose(metersToRoute([6.885, 45.85], lines: [far, near]), 55.59746332175475, within: 1e-9))
  }

  @Test("a segment across the antimeridian stays in one piece")
  func acrossTheAntimeridian() {
    let across = line([-179.999, -1], [-179.999, 1])
    #expect(
      isClose(metersToRoute([179.999, 0], lines: [across]), 222.38985329017936, within: 1e-9))
    #expect(metersToRoute([190, 0], lines: [line([-170, -1], [-170, 1])]) == 0)
  }

  /// A segment written from 170 to -20 runs 190 degrees eastward past the antimeridian; its far
  /// stretch is nearer the point a turn the other way.
  @Test("a long segment is measured from the point a turn the other way where that is nearer")
  func longSegment() {
    let twenty = 20 * metersPerDegreeMeanSphere
    #expect(
      isClose(metersToRoute([0, 0], lines: [line([170, 0], [-20, 0])]), twenty, within: 1e-6))
    #expect(
      isClose(metersToRoute([0, 0], lines: [line([-20, 0], [170, 0])]), twenty, within: 1e-6))
  }

  @Test("a vertex that names no place is bridged")
  func bridged() {
    let bridged = line([6.86, 45.85], [6.88], [.nan, 45], [6.9, 45.85])
    #expect(
      isClose(metersToRoute([6.88, 45.851], lines: [bridged]), 111.1949266442996, within: 1e-9))
  }

  @Test("with no segment to measure to, the distance is infinite")
  func noSegment() {
    #expect(metersToRoute([6.88, 45.851], lines: []) == .infinity)
    #expect(metersToRoute([6.88, 45.851], lines: [line([6.88, 45.85])]) == .infinity)
    #expect(
      metersToRoute([6.88, 45.851], lines: [GeoJSONLineString(coordinates: [])]) == .infinity)
  }

  /// A segment never runs from one line into the next.
  @Test("two lines are never joined")
  func neverJoined() {
    #expect(metersToRoute([0.5, 0], lines: [line([0, 0]), line([1, 0])]) == .infinity)
  }

  /// A point that names no place lies in no corridor.
  @Test("a point that names no place is infinitely far")
  func noPlace() {
    #expect(metersToRoute([6.88], lines: [straight]) == .infinity)
    #expect(metersToRoute([.nan, 45.85], lines: [straight]) == .infinity)
  }
}
