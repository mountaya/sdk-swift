import Testing

@testable import MountayaGeo

@Suite("bearingDegrees")
struct BearingDegreesTests {
  @Test("the bearing is a compass heading clockwise from north, on the great circle")
  func compass() {
    #expect(bearingDegrees(from: [0, 0], to: [0, 1]) == 0)
    #expect(bearingDegrees(from: [0, 0], to: [1, 0]) == 90)
    #expect(bearingDegrees(from: [0, 0], to: [0, -1]) == 180)
    #expect(bearingDegrees(from: [0, 0], to: [-1, 0]) == 270)
    // The initial heading of the great circle, not the planar angle of the two positions.
    #expect(isClose(bearingDegrees(from: [0, 0], to: [1, 1]), 44.99563645534485, within: 1e-9))
    #expect(
      isClose(
        bearingDegrees(from: [6.8652, 45.9237], to: [6.9271, 45.9682]), 44.023155178806974,
        within: 1e-9))
  }

  @Test("the longitudes are read the short way round")
  func shortWay() {
    #expect(isClose(bearingDegrees(from: [179.9, 0], to: [-179.9, 0]), 90, within: 1e-9))
    #expect(isClose(bearingDegrees(from: [-179.9, 0], to: [179.9, 0]), 270, within: 1e-9))
    #expect(isClose(bearingDegrees(from: [190, 0], to: [-169, 0]), 90, within: 1e-9))
  }

  /// A position written 180 and one written -180 are one place, read the short way round: no
  /// heading, rather than the 90 a turn's sine left over would answer.
  @Test("one place has no heading and answers 0")
  func onePlace() {
    #expect(bearingDegrees(from: [6.8652, 45.9237], to: [6.8652, 45.9237]) == 0)
    #expect(bearingDegrees(from: [180, 10], to: [-180, 10]) == 0)
    #expect(bearingDegrees(from: [6.8652, 45.9237, 1000], to: [6.8652, 45.9237, 2000]) == 0)
  }

  @Test("a heading a hair west of north stays under a turn")
  func hairWestOfNorth() {
    #expect(bearingDegrees(from: [0, 0], to: [-1e-16, 1]) == 0)
    let justWest = bearingDegrees(from: [0, 0], to: [-1e-9, 1])
    #expect(justWest < 360 && justWest > 359)
  }

  @Test("a position that names no place has no bearing")
  func noPlace() {
    #expect(bearingDegrees(from: [6], to: [6, 45]).isNaN)
    #expect(bearingDegrees(from: [6, 45], to: [.nan, 45]).isNaN)
    #expect(bearingDegrees(from: [6, .infinity], to: [6, 45]).isNaN)
  }

  @Test("a compass bearing is written within one turn, north a positive zero")
  func compassBearingWithinATurn() {
    #expect(compassBearing(-90) == 270)
    #expect(compassBearing(180) == 180)
    // A negative zero reads as zero, and a hair under zero that rounds to a turn is north.
    #expect(compassBearing(-0.0) == 0 && compassBearing(-0.0).sign == .plus)
    #expect(compassBearing(-1e-15) == 0)
    #expect(compassBearing(.nan).isNaN)
  }
}
