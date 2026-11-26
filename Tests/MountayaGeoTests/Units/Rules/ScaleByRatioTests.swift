import Testing

@testable import MountayaGeo

@Suite("scaleByRatio")
struct ScaleByRatioTests {
  /// A pair that reduces to a whole factor multiplies once, so the answer is the exact product.
  @Test("a factor that reduces to a whole number multiplies once")
  func wholeFactor() {
    #expect(scaleByRatio(1, numerator: 16_093_440, denominator: 3_048) == 5_280)
    #expect(scaleByRatio(42, numerator: 10_000, denominator: 10_000) == 42)
  }

  @Test("a factor that reduces to a whole fraction divides once")
  func wholeFraction() {
    #expect(scaleByRatio(7, numerator: 1, denominator: 100) == 0.07)
    #expect(scaleByRatio(1, numerator: 8_000, denominator: 1_000_000) == 0.008)
  }

  @Test("any other pair multiplies by its reduced numerator, then divides by its denominator")
  func otherPairs() {
    #expect(scaleByRatio(1, numerator: 8_000_000, denominator: 8_388_608) == 0.95367431640625)
    #expect(scaleByRatio(36, numerator: 10_000_000_000, denominator: 36_000_000_000) == 10)
  }

  @Test("a value that is not finite stays what it is")
  func notFinite() {
    #expect(scaleByRatio(.infinity, numerator: 3, denominator: 7) == .infinity)
    #expect(scaleByRatio(.nan, numerator: 3, denominator: 7).isNaN)
  }

  @Test("an inversion divides the reduced ratio by the value, and zero answers an infinity")
  func inversion() {
    #expect(
      isClose(invertByRatio(13.333333333333334, numerator: 60, denominator: 1), 4.5, within: 1e-12))
    #expect(
      isClose(
        invertByRatio(4.5, numerator: 57_936_384_000_000, denominator: 600_000_000_000),
        21.45792, within: 1e-12))
    #expect(invertByRatio(0, numerator: 60, denominator: 1) == .infinity)
    #expect(invertByRatio(-0.0, numerator: 60, denominator: 1) == -.infinity)
  }
}
