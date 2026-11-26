import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("profileTotals")
struct ProfileTotalsRuleTests {
  private let climb = buildElevationSeries(.lineString(GeoJSONLineString(coordinates: climbLine)))

  @Test("the totals are the one scan read at its last sample")
  func oneScan() throws {
    let totals = profileTotals(climb)
    #expect(totals.ascent == 495)
    #expect(totals.descent == 278)
    #expect(totals.elevationMin == 1_035)
    #expect(totals.elevationMax == 1_480)
    #expect(totals.distance == climb.totalDistance)
    #expect(isClose(try #require(totals.gradeMax), 14.144950577528101, within: 1e-9))
  }

  @Test("a series with no sample states its length alone")
  func lengthAlone() {
    #expect(
      profileTotals(
        ElevationSeries(points: [], totalDistance: 7_117.5, minElevation: nil, maxElevation: nil))
        == ProfileTotals(
          distance: 7_117.5, ascent: nil, descent: nil, elevationMin: nil, elevationMax: nil,
          gradeMax: nil))
  }

  @Test("the threshold and the window are the contract's")
  func constants() {
    #expect(elevationNoiseThresholdMeters == 5)
    #expect(gradeWindowMeters == 100)
  }
}
