import Testing

@testable import MountayaGeo

@Suite("ElevationDomain")
struct ElevationDomainTests {
  @Test("two domains are equal where the floors and ceilings are the same numbers")
  func equality() {
    #expect(ElevationDomain(min: 1_000, max: 1_850) == ElevationDomain(min: 1_000, max: 1_850))
    #expect(
      ElevationDomain(min: 1_000, max: 1_850).hashValue
        == ElevationDomain(min: 1_000, max: 1_850).hashValue)
    #expect(ElevationDomain(min: 0, max: 50) != ElevationDomain(min: -0.0, max: 50))
    #expect(ElevationDomain(min: .nan, max: 50) == ElevationDomain(min: .nan, max: 50))
  }
}
