import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("ProfileCharacteristics")
struct ProfileCharacteristicsTests {
  private func summary(distance: Double? = 12_317, partial: Bool = false) -> ProfileCharacteristics
  {
    ProfileCharacteristics(
      distance: distance, duration: 16_200, durationPartial: partial, ascent: 1_345, descent: 280,
      altitudeMin: 1_035, altitudeMax: 2_100, slopeMin: -9, slopeMax: 22, stopDuration: nil,
      trailDifficultyMin: .hiking,
      trailDifficultyMax: .alpineHiking)
  }

  @Test("two summaries are equal when every figure is, and hash alike")
  func equality() {
    #expect(summary() == summary())
    #expect(summary().hashValue == summary().hashValue)
    #expect(summary() != summary(partial: true))
    #expect(summary(distance: 0) != summary(distance: -0.0))
    #expect(summary(distance: .nan) == summary(distance: .nan))
    #expect(summary(distance: nil) != summary(distance: 0))
  }

  @Test("each figure is named by what it holds")
  func description() {
    let text = String(describing: summary())
    for figure in [
      "distance: Optional(12317.0)", "durationPartial: false", "ascent: Optional(1345)",
      "slopeMin: Optional(-9.0)", "stopDuration: nil", "rawValue: \"alpine-hiking\"",
    ] {
      #expect(text.contains(figure), "\(text)")
    }
  }
}
