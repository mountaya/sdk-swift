import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("itinerarySegmentRows")
struct ItinerarySegmentRowsTests {
  private let valley: GeoJSONGeometry = .lineString(
    GeoJSONLineString(coordinates: [[6, 45, 1_000], [6, 45.005, 1_100], [6, 45.01, 1_250]]))
  private let col: GeoJSONGeometry = .lineString(
    GeoJSONLineString(coordinates: [[6, 45.01, 1_250], [6, 45.015, 1_400], [6, 45.02, 1_320]]))
  private let leg = 1_111.9492664453662

  private var legs: [ItineraryLeg] {
    [
      ItineraryLeg(id: "s1", name: "Valley", geometry: valley),
      ItineraryLeg(id: "s2", name: "Col", color: "#e8590c", geometry: col),
    ]
  }

  private var series: ElevationSeries {
    buildElevationSeries(chainGeometry(legs))
  }

  @Test("each leg spans its own geometry and states what the scan reads")
  func derived() {
    let rows = itinerarySegmentRows(series, legs: legs)
    #expect(rows.map(\.key) == ["s1", "s2"] && rows.map(\.index) == [0, 1])
    #expect(isClose(rows[0].to, leg, within: 1e-6) && rows[1].from == rows[0].to)
    #expect(rows[0].metrics.sectionAscent == 250 && rows[0].metrics.altitudeMin == 1_000)
    #expect(rows[1].metrics.ascent == 400 && rows[1].metrics.descent == 80)
    #expect(rows[1].color == "#e8590c" && rows[0].memberIds.isEmpty)
    #expect(rows[1].metrics.duration == nil && rows[1].metrics.difficulty == nil)
  }

  @Test("the leg's own figures, then a stated figure, stand over the scan, the span derived")
  func stated() {
    var own = legs
    own[0].sectionDistance = 1_000
    own[0].duration = 1_800
    own[0].altitudeMax = 1_300
    let rows = itinerarySegmentRows(
      series, legs: own,
      stated: ["s2": ItinerarySegmentRowMetrics(sectionDistance: 2_000, difficulty: "T3")])
    #expect(rows[0].metrics.sectionDistance == 1_000 && rows[0].metrics.distance == 1_000)
    #expect(rows[0].metrics.duration == 1_800 && rows[0].metrics.altitudeMax == 1_300)
    #expect(rows[1].metrics.distance == 3_000 && rows[1].metrics.difficulty == "T3")
    #expect(isClose(rows[0].to, leg, within: 1e-6))
  }

  @Test("a stated running figure resets the totals for the rows after it")
  func reset() {
    let rows = itinerarySegmentRows(
      series, legs: legs + [ItineraryLeg(id: "t", name: "Transfer", sectionDistance: 500)],
      stated: ["s1": ItinerarySegmentRowMetrics(distance: 5_000, ascent: 300)])
    #expect(rows[0].metrics.distance == 5_000 && rows[0].metrics.ascent == 300)
    #expect(isClose(rows[1].metrics.distance ?? .nan, 5_000 + leg, within: 1e-6))
    #expect(rows[1].metrics.ascent == 450)
    #expect(isClose(rows[2].metrics.distance ?? .nan, 5_500 + leg, within: 1e-6))
  }

  @Test("a leg with no geometry spans nothing and derives nothing")
  func noGeometry() {
    let rows = itinerarySegmentRows(
      series, legs: [legs[0], ItineraryLeg(id: "t", name: "Transfer")])
    #expect(rows[1].from == rows[1].to)
    #expect(rows[1].metrics.sectionDistance == nil && rows[1].metrics.sectionAscent == nil)
    #expect(rows[1].metrics.ascent == 250)
  }

  @Test("a collapsed group is one row naming its members, and no elevation states lengths alone")
  func groupAndFlat() {
    let group = ItineraryLeg(id: "group:g1", memberIds: ["s2", "s3"], name: "Over", geometry: col)
    #expect(itinerarySegmentRows(series, legs: [legs[0], group])[1].memberIds == ["s2", "s3"])
    let flat = ElevationSeries(
      points: [], totalDistance: 2 * leg, minElevation: nil, maxElevation: nil)
    let rows = itinerarySegmentRows(flat, legs: legs)
    #expect(rows[0].metrics.ascent == nil && rows[0].metrics.altitudeMin == nil)
    #expect(isClose(rows[1].metrics.distance ?? .nan, 2 * leg, within: 1e-6))
  }

  @Test("a span is held to the series' length")
  func held() {
    let short = ElevationSeries(
      points: [], totalDistance: 100, minElevation: nil, maxElevation: nil)
    #expect(itinerarySegmentRows(short, legs: legs).map(\.to) == [100, 100])
  }
}
