import Testing

@testable import MountayaGeo

@Suite("climbCategoryFor")
struct ClimbCategoryForTests {
  @Test("the category is the hardest the score reaches")
  func hardest() {
    #expect(climbCategoryFor(lengthMeters: 2_000, avgGradePercent: 4) == .category4)
    #expect(climbCategoryFor(lengthMeters: 4_000, avgGradePercent: 4) == .category3)
    #expect(climbCategoryFor(lengthMeters: 4_000, avgGradePercent: 8) == .category2)
    #expect(climbCategoryFor(lengthMeters: 6_400, avgGradePercent: 10) == .category1)
    #expect(climbCategoryFor(lengthMeters: 8_000, avgGradePercent: 10) == .horsCategorie)
    #expect(
      climbCategoryFor(lengthMeters: 3_000, avgGradePercent: minClimbGradePercent) == .category4)
  }

  @Test("under the grade floor, the category floor, or with no number, there is none")
  func none() {
    #expect(climbCategoryFor(lengthMeters: 1_999, avgGradePercent: 4) == nil)
    #expect(climbCategoryFor(lengthMeters: 50_000, avgGradePercent: 2.9) == nil)
    #expect(climbCategoryFor(lengthMeters: .nan, avgGradePercent: 5) == nil)
    #expect(climbCategoryFor(lengthMeters: .infinity, avgGradePercent: 5) == nil)
  }
}
