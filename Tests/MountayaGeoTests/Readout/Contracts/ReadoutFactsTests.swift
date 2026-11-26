import Testing

@testable import MountayaGeo

@Suite("ReadoutFacts")
struct ReadoutFactsTests {
  @Test("a point's facts hold nothing the map does not hold")
  func empty() {
    let facts = ReadoutFacts(position: [6.8652, 45.9237], zoom: 14)
    #expect(facts.terrain == nil && facts.poi == nil && facts.zone == nil)
    #expect(facts.overlay == nil && facts.band == nil && facts.instant == nil)
  }
}
