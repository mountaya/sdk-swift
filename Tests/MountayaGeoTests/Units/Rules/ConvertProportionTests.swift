import Testing

@testable import MountayaGeo

@Suite("convertProportion")
struct ConvertProportionTests {
  @Test("a ratio of one is a hundred percent")
  func hundred() {
    #expect(convertProportion(0.5, from: .ratio, to: .percent) == 50)
    #expect(convertProportion(1, from: .ratio, to: .percent) == 100)
    #expect(convertProportion(7, from: .percent, to: .ratio) == 0.07)
    #expect(percentPerRatio == 100)
  }

  @Test("nothing is clamped")
  func nothingClamped() {
    #expect(convertProportion(2.5, from: .ratio, to: .percent) == 250)
    #expect(convertProportion(-50, from: .percent, to: .ratio) == -0.5)
  }

  @Test("a proportion in its own unit is returned as it is")
  func ownUnit() {
    for unit in ProportionUnit.allCases {
      #expect(convertProportion(0.1, from: unit, to: unit) == 0.1)
    }
  }
}
