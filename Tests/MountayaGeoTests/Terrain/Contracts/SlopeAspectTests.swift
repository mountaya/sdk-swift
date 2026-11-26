import Testing

@testable import MountayaGeo

@Suite("SlopeAspect")
struct SlopeAspectTests {
  /// Flat ground's nil aspect is not a north-facing slope's 0.
  @Test("no aspect is not a bearing of zero")
  func noAspect() {
    #expect(SlopeAspect(slope: 0, aspect: nil) != SlopeAspect(slope: 0, aspect: 0))
    #expect(SlopeAspect(slope: 0, aspect: nil) == SlopeAspect(slope: 0, aspect: nil))
    #expect(
      SlopeAspect(slope: 5, aspect: 90).hashValue == SlopeAspect(slope: 5, aspect: 90).hashValue)
    #expect(
      String(describing: SlopeAspect(slope: 5, aspect: nil))
        == "SlopeAspect(slope: 5.0, aspect: nil)")
  }

  /// Equal values hash alike: a slope of -0 is another value than one of 0, and NaN is the same as
  /// itself, as every value of the geo layer compares.
  @Test("two answers compare their numbers as the same numbers")
  func sameNumbers() {
    let unknown = SlopeAspect(slope: .nan, aspect: .nan)
    #expect(unknown == SlopeAspect(slope: .nan, aspect: .nan))
    #expect(unknown.hashValue == SlopeAspect(slope: .nan, aspect: .nan).hashValue)
    #expect(SlopeAspect(slope: 0, aspect: nil) != SlopeAspect(slope: -0.0, aspect: nil))
    #expect(SlopeAspect(slope: 5, aspect: 0) != SlopeAspect(slope: 5, aspect: -0.0))
    #expect(SlopeAspect(slope: 5, aspect: .nan) != SlopeAspect(slope: 5, aspect: nil))
  }
}
