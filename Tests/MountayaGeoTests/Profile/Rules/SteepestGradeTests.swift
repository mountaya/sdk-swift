import Testing

@testable import MountayaGeo

@Suite("steepestGrade")
struct SteepestGradeTests {
  private func degrees(ofRatio ratio: Double) -> Double {
    convertSlope(ratio, from: .ratio, to: .degrees)
  }

  /// Two samples 10 m apart rising 5 m are not a 26-degree cliff: the run is the window's full 100
  /// m.
  @Test("the grade is measured over the whole window, not between two close samples")
  func wholeWindow() throws {
    let points = samples((0, 0), (500, 0), (510, 5), (1_000, 5))
    let grade = try #require(steepestGrade(points, from: -.infinity, to: .infinity))
    #expect(isClose(grade, degrees(ofRatio: 0.05), within: 1e-12))
  }

  @Test("a stretch shorter than the window is measured end to end")
  func shortStretch() throws {
    let points = samples((0, 0), (1_000, 100))
    let grade = try #require(steepestGrade(points, from: 200, to: 250))
    #expect(isClose(grade, degrees(ofRatio: 0.1), within: 1e-12))
  }

  @Test("a stretch that only descends is zero, and one with no length has none")
  func descentAndNoLength() {
    #expect(steepestGrade(samples((0, 100), (1_000, 0)), from: 0, to: 1_000) == 0)
    #expect(steepestGrade(samples((0, 100), (1_000, 0)), from: 0, to: 1_000)?.sign == .plus)
    #expect(steepestGrade(samples((0, 0), (1_000, 100)), from: 400, to: 400) == nil)
    #expect(steepestGrade(samples((0, 0)), from: 0, to: 100) == nil)
    #expect(steepestGrade([], from: 0, to: 100) == nil)
  }
}
