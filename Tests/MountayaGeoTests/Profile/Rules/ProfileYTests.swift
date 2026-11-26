import Testing

@testable import MountayaGeo

@Suite("profileY")
struct ProfileYTests {
  private let domain = ElevationDomain(min: 1_000, max: 2_000)

  @Test("the ceiling stands under the top inset and the floor on the baseline, upside down")
  func down() {
    #expect(profileY(2_000, domain: domain) == 6)
    #expect(profileY(1_000, domain: domain) == 96)
    #expect(profileY(1_500, domain: domain) == 51)
    #expect(profileY(1_750, domain: domain) == 28.5)
  }

  @Test("an elevation outside the domain is held to the frame")
  func held() {
    #expect(profileY(2_500, domain: domain) == 6)
    #expect(profileY(500, domain: domain) == 96)
  }

  @Test("a domain with no span draws every elevation at the middle")
  func noSpan() {
    let flat = ElevationDomain(min: 1_200, max: 1_200)
    #expect(profileY(1_200, domain: flat) == 51)
    #expect(profileY(1_350, domain: flat) == 51)
    #expect(profileY(1_200, domain: ElevationDomain(min: 1_300, max: 1_200)) == 51)
  }
}
