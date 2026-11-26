import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("trailDifficultyRank")
struct TrailDifficultyRankTests {
  @Test("each grade is ranked within its scale")
  func ranks() {
    let ranks = [
      "hiking": 1, "mountain-hiking": 2, "demanding-mountain-hiking": 3, "alpine-hiking": 4,
      "demanding-alpine-hiking": 5, "difficult-alpine-hiking": 6, "mtb-0": 0, "mtb-1": 1,
      "mtb-2": 2, "mtb-3": 3, "mtb-4": 4, "mtb-5": 5, "mtb-6": 6,
    ]
    for (grade, rank) in ranks {
      #expect(
        trailDifficultyRank(RestSchema.TrailDifficultyType(rawValue: grade)) == rank, "\(grade)")
    }
  }

  @Test("an unknown grade, or one this build has never heard of, has no rank")
  func noRank() {
    #expect(trailDifficultyRank(.unknown) == nil)
    #expect(trailDifficultyRank(RestSchema.TrailDifficultyType(rawValue: "via-ferrata-c")) == nil)
  }
}
