import Testing

@testable import MountayaGeo

@Suite("extentDomain")
struct ExtentDomainTests {
  @Test("the narrowest span, the empty domain and the rounding steps are the contract's")
  func constants() {
    #expect(minDomainSpanMeters == 50)
    #expect(emptyElevationDomain == ElevationDomain(min: 0, max: 50))
    #expect(
      domainRoundingSteps == [
        DomainRoundingStep(stepMeters: 10, uptoSpanMeters: 200),
        DomainRoundingStep(stepMeters: 50, uptoSpanMeters: 1_000),
        DomainRoundingStep(stepMeters: 100, uptoSpanMeters: nil),
      ])
  }

  @Test("an extent is rounded outward by a step its span chooses")
  func rounded() {
    #expect(extentDomain(min: 1_035, max: 1_850) == ElevationDomain(min: 1_000, max: 1_850))
    #expect(extentDomain(min: 1_003, max: 1_203) == ElevationDomain(min: 1_000, max: 1_210))
    #expect(extentDomain(min: 1_003, max: 1_204) == ElevationDomain(min: 1_000, max: 1_250))
    #expect(extentDomain(min: 1_010, max: 2_010) == ElevationDomain(min: 1_000, max: 2_050))
    #expect(extentDomain(min: 1_010, max: 2_011) == ElevationDomain(min: 1_000, max: 2_100))
  }

  @Test("a flat extent is widened to fifty meters about its middle")
  func widened() {
    #expect(extentDomain(min: 100, max: 104) == ElevationDomain(min: 70, max: 130))
    #expect(extentDomain(min: 100, max: 100) == ElevationDomain(min: 70, max: 130))
  }

  @Test("an extent with a bound missing is the empty domain")
  func empty() {
    #expect(extentDomain(min: nil, max: 100) == emptyElevationDomain)
    #expect(extentDomain(min: 100, max: nil) == emptyElevationDomain)
  }
}
