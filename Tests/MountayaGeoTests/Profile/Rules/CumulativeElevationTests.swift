import Testing

@testable import MountayaGeo

@Suite("cumulativeElevation")
struct CumulativeElevationTests {
  @Test("a rise or fall under the threshold is not counted")
  func underTheThreshold() {
    let scan = cumulativeElevation(samplesEvery100Meters(1_000, 1_003, 1_001, 1_004, 1_006, 1_000))
    #expect(scan.ascent == [0, 0, 0, 0, 6, 6])
    #expect(scan.descent == [0, 0, 0, 0, 0, 6])
  }

  /// At exactly the threshold the step is counted.
  @Test("a step of exactly the threshold is counted and becomes the reference")
  func atTheThreshold() {
    let scan = cumulativeElevation(samplesEvery100Meters(0, elevationNoiseThresholdMeters, 0))
    #expect(scan.ascent == [0, 5, 5])
    #expect(scan.descent == [0, 0, 5])
  }

  @Test("no sample is no reading")
  func noSample() {
    #expect(cumulativeElevation([]).ascent.isEmpty)
  }
}
