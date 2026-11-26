import Testing

@testable import MountayaGeo

@Suite("fourDecimalPlaces")
struct FourDecimalPlacesTests {
  @Test("a value is written with four places in Latin digits and a full stop")
  func fourPlaces() {
    #expect(fourDecimalPlaces(0) == "0.0000")
    #expect(fourDecimalPlaces(6.8652) == "6.8652")
    #expect(fourDecimalPlaces(162.5) == "162.5000")
    #expect(fourDecimalPlaces(12.0464) == "12.0464")
  }

  /// The binary value is what is rounded: 6.86525 is held as 6.865249999..., and 1.00005 as
  /// 1.0000500000000001...
  @Test("the binary value is rounded, not the decimal it was written as")
  func binaryValue() {
    #expect(fourDecimalPlaces(6.86525) == "6.8652")
    #expect(fourDecimalPlaces(1.00005) == "1.0001")
    #expect(fourDecimalPlaces(45.00005) == "45.0001")
    #expect(fourDecimalPlaces(0.00005) == "0.0001")
    #expect(fourDecimalPlaces(0.00004999999999999999) == "0.0000")
  }

  /// 0.03125 is exactly halfway in binary, and a half rounds away from zero.
  @Test("a value exactly halfway takes the larger place")
  func halfway() {
    #expect(fourDecimalPlaces(0.03125) == "0.0313")
    #expect(fourDecimalPlaces(45.03125) == "45.0313")
  }

  @Test("a fraction that rounds to a whole one carries into the whole number")
  func carry() {
    #expect(fourDecimalPlaces(0.99995) == "1.0000")
    #expect(fourDecimalPlaces(179.99995) == "180.0000")
    #expect(fourDecimalPlaces(0.4999999999999999) == "0.5000")
  }

  @Test("the smallest values round to zero")
  func smallest() {
    #expect(fourDecimalPlaces(.leastNonzeroMagnitude) == "0.0000")
    #expect(fourDecimalPlaces(2.2250738585072014e-308) == "0.0000")
  }

  /// A whole number past what a 64-bit integer holds is written in full, never with an exponent.
  @Test("every finite magnitude is written in full")
  func inFull() {
    #expect(fourDecimalPlaces(4_503_599_627_370_495.5) == "4503599627370495.5000")
    #expect(fourDecimalPlaces(9_007_199_254_740_992) == "9007199254740992.0000")
    #expect(fourDecimalPlaces(1e19) == "10000000000000000000.0000")
    #expect(fourDecimalPlaces(9.223372036854775808e18) == "9223372036854775808.0000")
    #expect(fourDecimalPlaces(9.223372036854777856e18) == "9223372036854777856.0000")
    #expect(
      fourDecimalPlaces(.greatestFiniteMagnitude)
        == "179769313486231570814527423731704356798070567525844996598917476803157260780028538760"
        + "589558632766878171540458953514382464234321326889464182768467546703537516986049910576"
        + "551282076245490090389328944075868508455133942304583236903222948165808559332123348274"
        + "797826204144723168738177180919299881250404026184124858368.0000")
  }
}
