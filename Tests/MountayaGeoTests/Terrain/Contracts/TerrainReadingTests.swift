import Testing

@testable import MountayaGeo

@Suite("TerrainReading")
struct TerrainReadingTests {
  /// Flat ground's nil aspect is not a north-facing slope's 0.
  @Test("no aspect is not a bearing of zero, and numbers compare as the same numbers")
  func sameNumbers() {
    #expect(
      TerrainReading(elevation: 1, slope: 0, aspect: nil)
        != TerrainReading(elevation: 1, slope: 0, aspect: 0))
    #expect(
      TerrainReading(elevation: .nan, slope: 0, aspect: nil)
        == TerrainReading(elevation: .nan, slope: 0, aspect: nil))
    #expect(
      TerrainReading(elevation: 0, slope: 0, aspect: nil)
        != TerrainReading(elevation: -0.0, slope: 0, aspect: nil))
    #expect(
      TerrainReading(elevation: 5, slope: 2, aspect: 90).hashValue
        == TerrainReading(elevation: 5, slope: 2, aspect: 90).hashValue)
  }
}
