import Testing

@testable import MountayaGeo

@Suite("detectClimbs")
struct DetectClimbsTests {
  /// A sample every 100 m, written in kilometers the way a profile carries them: index / 10.
  private func profile(_ elevations: [Double]) -> [RouteProfilePoint] {
    elevations.enumerated().map {
      RouteProfilePoint(distanceKm: Double($0.offset) / 10, elevation: $0.element)
    }
  }

  private func flat(_ count: Int, at elevation: Double) -> [Double] {
    Array(repeating: elevation, count: count)
  }

  private func ramp(_ count: Int, from: Double, step: Double) -> [Double] {
    (0..<count).map { from + step * Double($0 + 1) }
  }

  @Test("a climb opens on its foot, closes at its summit and is categorized")
  func oneClimb() throws {
    let climbs = detectClimbs(
      profile(flat(11, at: 1_000) + ramp(40, from: 1_000, step: 6) + flat(10, at: 1_240)))
    try #require(climbs.count == 1)
    // 1.2 − 0.9 is a hair under 0.3 km, so the grade at 1.2 km is read from 0.8 km.
    #expect(climbs[0].startKm == 0.8)
    #expect(climbs[0].endKm == 5)
    #expect(climbs[0].peakElevation == 1_240)
    #expect(isClose(climbs[0].avgGradePercent, 5.714285714285714, within: 1e-12))
    #expect(climbs[0].category == .category3)
  }

  @Test("a flat as long as the close window ends the climb, and a shorter easing does not")
  func closeWindow() {
    let twoClimbs = profile(
      flat(11, at: 1_000) + ramp(30, from: 1_000, step: 7) + flat(10, at: 1_210)
        + ramp(30, from: 1_210, step: 7) + flat(10, at: 1_420))
    let spans = detectClimbs(twoClimbs).map { [$0.startKm, $0.endKm] }
    #expect(spans == [[0.8, 4], [4.8, 8]])
    let oneClimb = profile(
      flat(11, at: 1_000) + ramp(20, from: 1_000, step: 6) + flat(3, at: 1_120)
        + ramp(20, from: 1_120, step: 6) + flat(10, at: 1_240))
    #expect(detectClimbs(oneClimb).count == 1)
  }

  @Test("a climb to the end closes at the end")
  func toTheEnd() throws {
    let climbs = detectClimbs(profile(flat(11, at: 1_000) + ramp(50, from: 1_000, step: 8)))
    try #require(climbs.count == 1)
    #expect(climbs[0].endKm == 6)
    #expect(climbs[0].category == .category2)
  }

  @Test("a false flat, a descent, a short ramp and a single sample are no climb")
  func noClimb() {
    #expect(detectClimbs(profile(ramp(100, from: 1_000, step: 2))).isEmpty)
    #expect(detectClimbs(profile(ramp(60, from: 2_000, step: -6))).isEmpty)
    #expect(
      detectClimbs(
        profile(flat(11, at: 1_000) + ramp(4, from: 1_000, step: 12) + flat(10, at: 1_048))
      )
      .isEmpty)
    #expect(detectClimbs([RouteProfilePoint(distanceKm: 0, elevation: 1_000)]).isEmpty)
    #expect(detectClimbs([]).isEmpty)
  }

  @Test("the windows are the contract's")
  func windows() {
    #expect(
      [
        climbOpenWindowKm, climbOpenGradePercent, climbCloseGradePercent, climbCloseWindowKm,
        minClimbLengthKm,
      ] == [0.3, 3, 1, 0.5, 0.5])
  }
}
