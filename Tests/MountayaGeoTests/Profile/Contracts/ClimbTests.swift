import Testing

@testable import MountayaGeo

@Suite("Climb")
struct ClimbTests {
  private let climb = Climb(
    startKm: 0.8, endKm: 5, peakElevation: 1_240, avgGradePercent: 5.7, category: .category3)

  @Test("two climbs are equal when every figure and the category are, and hash alike")
  func equality() {
    let same = Climb(
      startKm: 0.8, endKm: 5, peakElevation: 1_240, avgGradePercent: 5.7, category: .category3)
    #expect(climb == same)
    #expect(climb.hashValue == same.hashValue)
    var harder = climb
    harder.category = .category2
    #expect(climb != harder)
    var unknown = climb
    unknown.avgGradePercent = .nan
    #expect(unknown == unknown)
    var negativeZero = climb
    negativeZero.startKm = -0.0
    var zero = climb
    zero.startKm = 0
    #expect(zero != negativeZero)
  }

  @Test("each figure is named by what it holds")
  func description() {
    #expect(
      String(describing: climb)
        == "Climb(startKm: 0.8, endKm: 5.0, peakElevation: 1240.0, avgGradePercent: 5.7, category: MountayaGeo.ClimbCategory.category3)"
    )
  }
}
