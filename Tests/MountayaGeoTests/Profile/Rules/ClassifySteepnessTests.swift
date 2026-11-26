import Testing

@testable import MountayaGeo

@Suite("classifySteepness")
struct ClassifySteepnessTests {
  @Test("a slope falls in the last class it reaches")
  func lastReached() {
    #expect(classifySteepness(25) == .from25To30)
    #expect(classifySteepness(30) == .from30To35)
    #expect(classifySteepness(44.999) == .from40To45)
    #expect(classifySteepness(60) == .from45)
  }

  @Test("a slope under the first class, a descent or no number has none")
  func none() {
    #expect(classifySteepness(24.999) == nil)
    #expect(classifySteepness(-30) == nil)
    #expect(classifySteepness(.nan) == nil)
    #expect(steepnessOverlaySlug == "steepness")
  }
}
