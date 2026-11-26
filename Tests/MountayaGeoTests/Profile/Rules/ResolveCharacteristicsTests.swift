import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("resolveCharacteristics")
struct ResolveCharacteristicsTests {
  private let derived = ProfileTotals(
    distance: 24_310, ascent: 1_520.4, descent: 1_401, elevationMin: 1_030, elevationMax: 1_852,
    gradeMax: 17.9)

  @Test("with nothing stated every figure is the geometry's, the stated ones none")
  func derivedOnly() {
    let resolved = resolveCharacteristics(derived, stated: nil)
    #expect(
      resolved
        == ResolvedCharacteristics(
          distance: 24_310, ascent: 1_520.4, descent: 1_401, altitudeMin: 1_030, altitudeMax: 1_852,
          slopeMax: 17.9))
    #expect(
      resolved.duration == nil && resolved.slopeMin == nil && resolved.trailDifficultyMax == nil)
  }

  @Test("a stated figure stands over the derived one, figure by figure")
  func stated() {
    let stated = ProfileCharacteristics(
      distance: 24_300, duration: 32_400, durationPartial: false, ascent: 1_531, descent: nil,
      altitudeMin: 1_035, altitudeMax: nil, slopeMin: -15.2, slopeMax: nil, stopDuration: nil,
      trailDifficultyMin: "T1", trailDifficultyMax: "T3")
    let resolved = resolveCharacteristics(derived, stated: stated)
    #expect(resolved.distance == 24_300 && resolved.duration == 32_400 && resolved.ascent == 1_531)
    #expect(
      resolved.descent == 1_401 && resolved.altitudeMin == 1_035 && resolved.altitudeMax == 1_852)
    #expect(resolved.slopeMin == -15.2 && resolved.slopeMax == 17.9)
    #expect(resolved.trailDifficultyMin == "T1" && resolved.trailDifficultyMax == "T3")
  }
}
