import Testing

@testable import MountayaGeo

@Suite("AltitudeRange")
struct AltitudeRangeTests {
  @Test("two bands are equal where both numbers are the same")
  func equality() {
    #expect(AltitudeRange(min: 1_035, max: 1_850) == AltitudeRange(min: 1_035, max: 1_850))
    #expect(AltitudeRange(min: 1_035, max: 1_850) != AltitudeRange(min: 1_850, max: 1_035))
    #expect(
      AltitudeRange(min: 0, max: 1).hashValue == AltitudeRange(min: 0, max: 1).hashValue)
  }
}
