import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("rangeTotals")
struct RangeTotalsTests {
  private let climb = buildElevationSeries(.lineString(GeoJSONLineString(coordinates: climbLine)))

  @Test("the whole itinerary is its totals")
  func whole() throws {
    let whole = rangeTotals(climb, from: 0, to: climb.totalDistance)
    let totals = profileTotals(climb)
    #expect(whole.ascent == totals.ascent)
    #expect(whole.descent == totals.descent)
    #expect(isClose(try #require(whole.gradeMax), try #require(totals.gradeMax), within: 1e-12))
  }

  /// The noise threshold never restarts at a boundary.
  @Test("two stretches sum to the whole")
  func sum() throws {
    let first = rangeTotals(climb, from: 0, to: 3_000)
    let rest = rangeTotals(climb, from: 3_000, to: climb.totalDistance)
    #expect(isClose(try #require(first.ascent) + (try #require(rest.ascent)), 495, within: 1e-9))
    #expect(isClose(try #require(first.descent) + (try #require(rest.descent)), 278, within: 1e-9))
    #expect(first.distance == 3_000)
  }

  @Test("a range given backwards is read in order")
  func backwards() {
    #expect(
      rangeTotals(climb, from: 1_000, to: 5_000) == rangeTotals(climb, from: 5_000, to: 1_000))
  }

  @Test("a stretch between two samples has a band and a grade of its own")
  func between() throws {
    let stretch = rangeTotals(climb, from: 2_000, to: 2_500)
    #expect(isClose(try #require(stretch.elevationMin), 1_135.1505171931315, within: 1e-9))
    #expect(isClose(try #require(stretch.elevationMax), 1_225.4458140834251, within: 1e-9))
    #expect(stretch.descent == 0)
    #expect(stretch.gradeMax != nil)
  }

  @Test("a stretch past the samples states no grade, and a series with none its length alone")
  func past() {
    let past = rangeTotals(climb, from: climb.totalDistance, to: 8_000)
    #expect(past.ascent == 0)
    #expect(past.elevationMin == 1_252)
    #expect(past.gradeMax == nil)
    #expect(
      rangeTotals(
        ElevationSeries(points: [], totalDistance: 0, minElevation: nil, maxElevation: nil),
        from: 500, to: 0)
        == ProfileTotals(
          distance: 500, ascent: nil, descent: nil, elevationMin: nil, elevationMax: nil,
          gradeMax: nil))
  }
}
