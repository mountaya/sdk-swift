import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("profileCharacteristics")
struct ProfileCharacteristicsRuleTests {
  private func difficulty(_ grades: String...) -> [RestSchema.TrailDifficultyInfo] {
    grades.map {
      RestSchema.TrailDifficultyInfo(
        from_index: 0, to_index: 1, value: RestSchema.TrailDifficultyType(rawValue: $0))
    }
  }

  @Test("the figures are summed, and the ranges take the extremes")
  func sums() {
    let summary = profileCharacteristics([
      restSegment(
        distance: 7_117, duration: 9_000, ascent: 495, descent: 278, altitude: (1_035, 1_480),
        gradient: (-9, 14)),
      restSegment(
        distance: 5_200, duration: 7_200, ascent: 850, descent: 2, altitude: (1_252, 2_100),
        gradient: (-4, 22)),
    ])
    #expect(summary.distance == 12_317)
    #expect(summary.duration == 16_200)
    #expect(summary.ascent == 1_345)
    #expect(summary.descent == 280)
    #expect(summary.altitudeMin == 1_035)
    #expect(summary.altitudeMax == 2_100)
    #expect(summary.slopeMin == -9)
    #expect(summary.slopeMax == 22)
    #expect(!summary.durationPartial)
  }

  @Test("a figure no segment states is nil, and a duration some lack is partial")
  func partial() {
    let partial = profileCharacteristics([
      restSegment(distance: 1_000, duration: 600), restSegment(distance: 2_000),
    ])
    #expect(partial.duration == 600)
    #expect(partial.durationPartial)
    #expect(partial.ascent == nil)
    let nothing = profileCharacteristics([restSegment(), restSegment()])
    #expect(nothing.distance == nil)
    #expect(nothing.duration == nil)
    #expect(!nothing.durationPartial)
    #expect(!profileCharacteristics([]).durationPartial)
  }

  @Test("the difficulty range is the easiest and the hardest ranked grade")
  func difficultyRange() {
    let summary = profileCharacteristics([
      restSegment(trailDifficulty: difficulty("hiking", "mountain-hiking")),
      restSegment(trailDifficulty: difficulty("alpine-hiking")),
    ])
    #expect(summary.trailDifficultyMin?.rawValue == "hiking")
    #expect(summary.trailDifficultyMax?.rawValue == "alpine-hiking")
    let unknown = profileCharacteristics([
      restSegment(trailDifficulty: difficulty("unknown", "mtb-2", "unknown"))
    ])
    #expect(unknown.trailDifficultyMin?.rawValue == "mtb-2")
    #expect(unknown.trailDifficultyMax?.rawValue == "mtb-2")
    #expect(
      profileCharacteristics([restSegment(trailDifficulty: difficulty("unknown"))])
        .trailDifficultyMax == nil)
  }

  /// Two grades of one rank on two scales: the first listed holds the bound.
  @Test("of two grades of one rank, the first listed holds")
  func firstListed() {
    let summary = profileCharacteristics([
      restSegment(trailDifficulty: difficulty("mtb-1", "hiking"))
    ])
    #expect(summary.trailDifficultyMin?.rawValue == "mtb-1")
    #expect(summary.trailDifficultyMax?.rawValue == "mtb-1")
  }

  @Test("the stops are summed from the waypoints")
  func stops() {
    let stops = [
      restWaypoint(timing: RestSchema.WaypointTiming { $0.stop_duration = 900 }),
      restWaypoint(),
      restWaypoint(timing: RestSchema.WaypointTiming { $0.stop_duration = 300 }),
    ]
    #expect(profileCharacteristics([restSegment()], waypoints: stops).stopDuration == 1_200)
    #expect(
      profileCharacteristics([restSegment()], waypoints: [restWaypoint()]).stopDuration == nil)
  }

  /// Kotlin's Int sum wraps too; a Swift `+` would trap.
  @Test("a sum past the range of Int wraps rather than traps")
  func wraps() {
    let summary = profileCharacteristics([restSegment(ascent: Int.max), restSegment(ascent: 1)])
    #expect(summary.ascent == Int.min)
  }
}
