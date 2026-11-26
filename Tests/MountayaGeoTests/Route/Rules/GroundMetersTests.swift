import Testing

@testable import MountayaGeo

@Suite("groundMeters")
struct GroundMetersTests {
  private let degree = metersPerDegreeMeanSphere
  private let equator: [[Double]] = [[0, 0], [1, 0], [2, 0], [4, 0]]

  @Test("a route with no jump is its length along the line")
  func noJump() {
    #expect(groundMeters(RouteGeometry(line: equator)) == cumulativeMeters(equator))
  }

  /// The vertex a jump lands on stands at the distance of the vertex it left.
  @Test("a jump charges nothing for its leg, and jumps one after another each charge nothing")
  func jump() {
    #expect(
      areClose(
        groundMeters(RouteGeometry(line: equator, jumps: [2])), [0, degree, degree, 3 * degree],
        within: 1e-6))
    #expect(
      areClose(
        groundMeters(RouteGeometry(line: equator, jumps: [1, 3])), [0, 0, degree, degree],
        within: 1e-6))
  }

  @Test("a jump the line has no leg to is none, and a jump named twice is one")
  func noLeg() {
    for jumps in [[0], [4], [-1], [Int.max]] {
      #expect(
        groundMeters(RouteGeometry(line: equator, jumps: jumps)) == cumulativeMeters(equator),
        "for \(jumps)")
    }
    #expect(
      areClose(
        groundMeters(RouteGeometry(line: equator, jumps: [2, 2])), [0, degree, degree, 3 * degree],
        within: 1e-6))
  }

  @Test("a line with no vertex has no distance")
  func empty() {
    #expect(groundMeters(RouteGeometry(line: [], jumps: [1])) == [])
  }
}
