import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("ResolvedCharacteristics")
struct ResolvedCharacteristicsTests {
  @Test("every figure is nil unless given, and two are equal where every figure is")
  func equality() {
    let empty = ResolvedCharacteristics()
    #expect(empty.distance == nil && empty.trailDifficultyMax == nil && empty.slopeMin == nil)
    let figures = ResolvedCharacteristics(distance: 24_300, ascent: 1_531, trailDifficultyMax: "T3")
    #expect(
      figures == ResolvedCharacteristics(distance: 24_300, ascent: 1_531, trailDifficultyMax: "T3"))
    #expect(
      figures.hashValue
        == ResolvedCharacteristics(distance: 24_300, ascent: 1_531, trailDifficultyMax: "T3")
        .hashValue)
    #expect(
      figures != ResolvedCharacteristics(distance: 24_300, ascent: 1_531, trailDifficultyMax: "T4"))
    #expect(ResolvedCharacteristics(ascent: 0) != ResolvedCharacteristics(ascent: -0.0))
  }
}
