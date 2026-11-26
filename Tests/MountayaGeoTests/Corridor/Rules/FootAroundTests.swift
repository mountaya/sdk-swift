import Foundation
import Testing

@testable import MountayaGeo

@Suite("footAround")
struct FootAroundTests {
  private let from: [Double] = [6.86, 45.85]
  private let to: [Double] = [6.9, 45.85]

  private func foot(_ point: [Double], from start: [Double], to end: [Double])
    -> (distance: Double, fraction: Double)
  {
    footAround(
      point, metersPerDegreeLongitude: metersPerDegreeLongitudeAt(point[1]), from: start, to: end)
  }

  @Test("the foot stands where the point projects in the local plane")
  func projection() {
    let (distance, fraction) = foot([6.88, 45.851], from: from, to: to)

    #expect(isClose(distance, 111.1949266442996, within: 1e-9))
    #expect(isClose(fraction, 0.5, within: 1e-12))
  }

  @Test("a foot past an end stands on that end")
  func pastAnEnd() {
    let (distance, fraction) = foot([6.95, 45.85], from: from, to: to)

    #expect(isClose(distance, 3_872.581345548356, within: 1e-9))
    #expect(fraction == 1)
    #expect(foot([6.8, 45.85], from: from, to: to).fraction == 0)
  }

  @Test("a segment that is one point has its foot there, at the start")
  func onePoint() {
    let (distance, fraction) = foot([6.86, 45.851], from: from, to: from)

    #expect(fraction == 0)
    #expect(isClose(distance, metersPerDegreeMeanSphere * 0.001, within: 1e-9))
  }

  /// 170 to -20 runs 190 degrees eastward past the antimeridian: its far end is 20 degrees from the
  /// point the other way round, and the foot there is the one answered.
  @Test("the foot past the meridian half a turn away is the nearer one")
  func turnedFoot() {
    let (distance, fraction) = foot([0, 0], from: [170, 0], to: [-20, 0])

    #expect(isClose(distance, 20 * metersPerDegreeMeanSphere, within: 1e-6))
    #expect(fraction == 1)
  }

  @Test("a segment across the antimeridian is measured in one piece")
  func acrossTheAntimeridian() {
    let (distance, fraction) = foot([179.999, 0], from: [-179.999, -1], to: [-179.999, 1])

    #expect(isClose(distance, 222.38985329017936, within: 1e-9))
    #expect(isClose(fraction, 0.5, within: 1e-12))
  }

  @Test("the degree of longitude shrinks with the latitude")
  func degreeOfLongitude() {
    #expect(metersPerDegreeLongitudeAt(0) == metersPerDegreeMeanSphere)
    #expect(
      isClose(
        metersPerDegreeLongitudeAt(60), metersPerDegreeMeanSphere * cos(60 * Double.pi / 180),
        within: 1e-9))
  }
}
