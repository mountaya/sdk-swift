import Testing

@testable import MountayaGeo

@Suite("domainTicks")
struct DomainTicksTests {
  @Test("a scale is labelled at its floor, its middle and its ceiling")
  func ticks() {
    #expect(domainTicks(ElevationDomain(min: 1_000, max: 1_850)) == [1_000, 1_425, 1_850])
    #expect(domainTicks(ElevationDomain(min: 0, max: 50)) == [0, 25, 50])
  }
}
