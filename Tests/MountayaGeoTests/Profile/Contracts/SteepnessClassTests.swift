import Testing

@testable import MountayaGeo

@Suite("SteepnessClass")
struct SteepnessClassTests {
  @Test("each class is spelled by its id and starts where the previous ends")
  func classes() {
    #expect(SteepnessClass.allCases.map(\.id) == ["25-30", "30-35", "35-40", "40-45", "45+"])
    #expect(SteepnessClass.allCases.map(\.fromDegrees) == [25, 30, 35, 40, 45])
  }
}
