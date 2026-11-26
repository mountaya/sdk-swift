import Testing

@testable import MountayaGeo

@Suite("profileDomain")
struct ProfileDomainTests {
  private let series = ElevationSeries(
    points: samples((0, 1_000), (1_000, 1_100), (2_000, 1_500), (3_000, 1_900), (4_000, 1_300)),
    totalDistance: 4_000, minElevation: 1_000, maxElevation: 1_900)

  @Test("with no window the stated extent is framed")
  func whole() {
    #expect(profileDomain(series) == ElevationDomain(min: 1_000, max: 1_900))
  }

  @Test("a window frames the stretch it holds, each end read on the curve, in either order")
  func windowed() {
    #expect(
      profileDomain(series, window: ProfileRange(from: 0, to: 1_500))
        == ElevationDomain(min: 1_000, max: 1_300))
    #expect(
      profileDomain(series, window: ProfileRange(from: 1_500, to: 0))
        == ElevationDomain(min: 1_000, max: 1_300))
    #expect(
      profileDomain(series, window: ProfileRange(from: 2_200, to: 2_600))
        == ElevationDomain(min: 1_580, max: 1_740))
  }

  @Test("a window holding the whole curve, or none of it, frames the stated extent")
  func stated() {
    #expect(
      profileDomain(series, window: ProfileRange(from: 0, to: 4_000))
        == ElevationDomain(min: 1_000, max: 1_900))
    #expect(
      profileDomain(series, window: ProfileRange(from: 5_000, to: 6_000))
        == ElevationDomain(min: 1_000, max: 1_900))
  }

  @Test("a series with no elevation is framed from 0 to 50")
  func empty() {
    let flat = ElevationSeries(
      points: [], totalDistance: 5_000, minElevation: nil, maxElevation: nil)
    #expect(profileDomain(flat) == emptyElevationDomain)
    #expect(profileDomain(flat, window: ProfileRange(from: 0, to: 100)) == emptyElevationDomain)
  }
}
