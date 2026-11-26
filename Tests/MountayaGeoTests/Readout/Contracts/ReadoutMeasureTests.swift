import Testing

@testable import MountayaGeo

@Suite("ReadoutMeasure")
struct ReadoutMeasureTests {
  @Test("each measure is spelled as the contract spells it")
  func spelling() {
    #expect(ReadoutMeasure(rawValue: "snowfall") == .snowfall)
    #expect(ReadoutMeasure.speed.rawValue == "speed")
  }
}
