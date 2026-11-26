import Testing

@testable import MountayaGeo

@Suite("folded")
struct FoldedTests {
  @Test("a figure either side leaves unstated is left out, and none stated is none")
  func folding() {
    #expect(folded(2, 3, by: +) == 5)
    #expect(folded(2, nil, by: +) == 2)
    #expect(folded(nil, 3, by: +) == 3)
    #expect(folded(Int?.none, nil, by: +) == nil)
    #expect(folded(-9.0, -4.0, by: minimumNumber) == -9)
  }
}
