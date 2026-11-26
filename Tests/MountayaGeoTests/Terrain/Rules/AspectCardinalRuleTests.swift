import Testing

@testable import MountayaGeo

@Suite("aspectCardinal")
struct AspectCardinalRuleTests {
  @Test("a bearing names the eighth of the compass centred on its heading")
  func sectors() {
    #expect(aspectCardinal(0) == .north)
    #expect(aspectCardinal(22.4999) == .north)
    #expect(aspectCardinal(135) == .southEast)
    #expect(aspectCardinal(337.4999) == .northWest)
  }

  @Test("a bearing on an edge names the sector clockwise of it")
  func edges() {
    #expect(aspectCardinal(22.5) == .northEast)
    #expect(aspectCardinal(337.5) == .north)
  }

  @Test("a bearing is folded by whole turns, and no finite number names none")
  func folded() {
    #expect(aspectCardinal(360) == .north)
    #expect(aspectCardinal(-45) == .northWest)
    #expect(aspectCardinal(810) == .east)
    #expect(aspectCardinal(-0.0) == .north)
    #expect(aspectCardinal(.nan) == nil)
    #expect(aspectCardinal(-.infinity) == nil)
  }
}
