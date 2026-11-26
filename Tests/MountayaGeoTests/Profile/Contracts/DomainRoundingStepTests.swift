import Testing

@testable import MountayaGeo

@Suite("DomainRoundingStep")
struct DomainRoundingStepTests {
  @Test("two steps are equal where their numbers are, an unbounded step only to another")
  func equality() {
    #expect(
      DomainRoundingStep(stepMeters: 10, uptoSpanMeters: 200)
        == DomainRoundingStep(stepMeters: 10, uptoSpanMeters: 200))
    #expect(
      DomainRoundingStep(stepMeters: 100, uptoSpanMeters: nil)
        != DomainRoundingStep(stepMeters: 100, uptoSpanMeters: 1_000))
    #expect(
      DomainRoundingStep(stepMeters: 100, uptoSpanMeters: nil).hashValue
        == DomainRoundingStep(stepMeters: 100, uptoSpanMeters: nil).hashValue)
  }
}
