import Testing

@testable import MountayaGeo

@Suite("markerPasses")
struct MarkerPassesTests {
  /// Out along the equator to 0.03 degrees and back: a place on it is passed twice.
  private let outAndBack: [[[Double]]] = [[0, 0.01, 0.02, 0.03, 0.02, 0.01, 0].map { [$0, 0] }]

  @Test("the legs are laid end to end, and the jump between lines is none")
  func legs() {
    let legs = walkLegs([[[0, 0], [1, 0]], [[5, 0], [.nan, 0], [6, 0]]])
    #expect(legs.count == 2)
    #expect(legs.map(\.start) == [0, haversineMeters(from: [0, 0], to: [1, 0])])
    #expect([legs[1].previous[0], legs[1].current[0]] == [5, 6])
  }

  @Test("each run of near legs is one pass, at its nearest point")
  func runs() {
    let passes = markerPasses(walkLegs(outAndBack), position: [0.01, 0], proximityMeters: 60)
    #expect(passes.count == 2)
    #expect(isClose(passes[0].distance, 0.01 * metersPerDegreeMeanSphere, within: 1e-6))
    #expect(isClose(passes[1].distance, 0.05 * metersPerDegreeMeanSphere, within: 1e-6))
    #expect(isClose(passes[0].meters, 0, within: 1e-9))
  }

  @Test("a place the line never comes near, or that names no place, has no pass")
  func noPass() {
    let legs = walkLegs(outAndBack)
    #expect(markerPasses(legs, position: [0.01, 0.01], proximityMeters: 60).isEmpty)
    #expect(markerPasses(legs, position: [.nan, 0], proximityMeters: 60).isEmpty)
    #expect(markerPasses(legs, position: [0.01], proximityMeters: 60).isEmpty)
  }

  /// 360 degrees east is the prime meridian: the place stands where the line starts and ends.
  @Test("a place written a turn away is measured where it stands")
  func aTurnAway() {
    let passes = markerPasses(walkLegs(outAndBack), position: [360, 0], proximityMeters: 60)
    #expect(passes.count == 2)
    #expect(passes.first?.distance == 0)
    #expect(isClose(passes.last?.distance ?? .nan, 0.06 * metersPerDegreeMeanSphere, within: 1e-6))
  }
}
