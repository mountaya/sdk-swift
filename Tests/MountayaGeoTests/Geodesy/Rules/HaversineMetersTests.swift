import Testing

@testable import MountayaGeo

@Suite("haversineMeters")
struct HaversineMetersTests {
  @Test("the sphere is the mean Earth's, and its degree is the radius times pi over 180")
  func sphere() {
    #expect(earthRadiusMeters == 6_371_000)
    // The radius times the precomputed degree, which `(R * pi) / 180` would miss by an ulp.
    #expect(metersPerDegreeMeanSphere == 111_194.926_644_558_74)
  }

  @Test("one degree of the equator is one degree of the mean sphere")
  func oneDegree() {
    #expect(
      isClose(haversineMeters(from: [0, 0], to: [1, 0]), metersPerDegreeMeanSphere, within: 1e-6))
  }

  @Test("a position is no distance from itself, and the poles are half the circumference apart")
  func itselfAndThePoles() {
    #expect(haversineMeters(from: [6.8652, 45.9237], to: [6.8652, 45.9237]) == 0)
    #expect(
      isClose(haversineMeters(from: [0, 90], to: [0, -90]), .pi * earthRadiusMeters, within: 1e-6))
  }

  @Test("the antimeridian is crossed the short way round")
  func antimeridian() {
    #expect(
      isClose(
        haversineMeters(from: [179.9, 0], to: [-179.9, 0]), 22_238.985328911924, within: 1e-6))
  }

  /// The term is held within 0 to 1 before its root, so two antipodes never measure NaN.
  @Test("two antipodes written any way measure half the circumference")
  func antipodes() {
    #expect(
      isClose(haversineMeters(from: [0, 0], to: [180, 0]), .pi * earthRadiusMeters, within: 1e-6))
    #expect(
      isClose(
        haversineMeters(from: [-37.5, 12.25], to: [142.5, -12.25]), .pi * earthRadiusMeters,
        within: 1e-6))
  }

  @Test("a position that names no place measures NaN")
  func noPlace() {
    #expect(haversineMeters(from: [6.88], to: [6, 45]).isNaN)
    #expect(haversineMeters(from: [6, 45], to: []).isNaN)
    #expect(haversineMeters(from: [.nan, 45], to: [6, 45]).isNaN)
    #expect(haversineMeters(from: [6, 45], to: [6, .infinity]).isNaN)
  }

  @Test("an altitude is no part of the distance")
  func altitude() {
    #expect(
      haversineMeters(from: [6.8652, 45.9237], to: [6.9271, 45.9682])
        == haversineMeters(from: [6.8652, 45.9237, 1035], to: [6.9271, 45.9682, 1252]))
  }
}
