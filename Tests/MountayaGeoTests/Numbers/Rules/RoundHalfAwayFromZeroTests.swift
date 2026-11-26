import Testing

@testable import MountayaGeo

@Suite("roundHalfAwayFromZero")
struct RoundHalfAwayFromZeroTests {
  /// 0.85 is held as 0.84999999999999997..., and 2.675 as 2.67499999999999982...: the decimal a
  /// reader writes is halfway, so each rounds up, where the binary value rounds down. Scaling and
  /// calling `Double.rounded()` reads the binary value: 1.005 × 100 is 100.49999999999999.
  @Test("the decimal value is rounded, not the binary one")
  func decimalValue() {
    #expect(roundHalfAwayFromZero(0.85, fractionDigits: 1) == 0.9)
    #expect(roundHalfAwayFromZero(2.675, fractionDigits: 2) == 2.68)
    #expect(roundHalfAwayFromZero(1.005, fractionDigits: 2) == 1.01)
    #expect(roundHalfAwayFromZero(24.3, fractionDigits: 1) == 24.3)
    #expect(roundHalfAwayFromZero(0.528, fractionDigits: 1) == 0.5)
    #expect((1.005 * 100).rounded() / 100 == 1)
  }

  @Test("a half rounds away from zero on both sides")
  func halfAwayFromZero() {
    #expect(roundHalfAwayFromZero(2.5, fractionDigits: 0) == 3)
    #expect(roundHalfAwayFromZero(-2.5, fractionDigits: 0) == -3)
    #expect(roundHalfAwayFromZero(0.5, fractionDigits: 0) == 1)
    #expect(roundHalfAwayFromZero(-0.85, fractionDigits: 1) == -0.9)
    #expect(roundHalfAwayFromZero(2.4999999999999996, fractionDigits: 0) == 2)
  }

  @Test("a value that rounds to zero is a positive zero")
  func positiveZero() {
    for (value, digits) in [(-0.3, 0), (-0.04, 1), (-0.0, 0), (0.4, 0)] {
      let rounded = roundHalfAwayFromZero(value, fractionDigits: digits)
      #expect(rounded == 0)
      #expect(rounded.sign == .plus, "\(value) rounds to \(rounded)")
    }
  }

  @Test("a value that is not finite, or too large to hold a fraction, is left as it is")
  func leftAsItIs() {
    #expect(roundHalfAwayFromZero(.nan, fractionDigits: 1).isNaN)
    #expect(roundHalfAwayFromZero(.infinity, fractionDigits: 0) == .infinity)
    #expect(roundHalfAwayFromZero(1e300, fractionDigits: 2) == 1e300)
    #expect(roundHalfAwayFromZero(12, fractionDigits: -3) == 12)
    #expect(roundHalfAwayFromZero(12.345, fractionDigits: 99) == 12.345)
    #expect(maxFractionDigits == 20)
  }

  @Test("the exact powers of ten are exact")
  func powers() {
    #expect(powerOfTen(0) == 1)
    #expect(powerOfTen(3) == 1000)
    #expect(powerOfTen(22) == 1e22)
    #expect(abs(powerOfTen(23) - 1e23) <= 1e8)
    #expect(powerOfTen(-2) == 1)
  }
}
