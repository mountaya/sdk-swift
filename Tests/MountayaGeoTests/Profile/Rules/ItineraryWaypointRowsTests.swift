import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("itineraryWaypointRows")
struct ItineraryWaypointRowsTests {
  private let line: GeoJSONGeometry = .lineString(
    GeoJSONLineString(coordinates: [[6, 45, 1_000], [6, 45.005, 1_200], [6, 45.01, 1_500]]))
  private var series: ElevationSeries { buildElevationSeries(line) }

  @Test("the places in itinerary order, each reached from the one before")
  func ordered() {
    let rows = itineraryWaypointRows(
      series, geometry: line,
      places: [
        ProfilePlace(.atDistance(id: "col", distance: 500), name: "Col"),
        ProfilePlace(.atDistance(id: "hut", distance: 200), name: "Hut"),
      ])
    #expect(rows.map(\.key) == ["hut#0", "col#0"] && rows.map(\.index) == [0, 1])
    #expect(rows.map(\.from) == [0, 200] && rows.map(\.to) == [200, 500])
    #expect(isClose(rows[0].metrics.altitude ?? .nan, 1_071.9457284734617, within: 1e-9))
    #expect(isClose(rows[1].metrics.sectionAscent ?? .nan, 107.91859271019243, within: 1e-9))
    #expect(rows[1].metrics.distance == 500 && rows[1].metrics.sectionDistance == 300)
  }

  @Test("a stated figure carries into the running totals after it, an unnamed place stating none")
  func stated() {
    let rows = itineraryWaypointRows(
      series, geometry: line,
      places: [
        ProfilePlace(
          .atDistance(id: "hut", distance: 400), name: "Hut",
          metrics: ItinerarySegmentRowMetrics(sectionDistance: 450, ascent: 250)),
        ProfilePlace(.atDistance(id: "col", distance: 900), name: "Col"),
      ])
    #expect(rows[0].metrics.distance == 450 && rows[0].metrics.ascent == 250)
    #expect(rows[1].metrics.distance == 950)
    #expect(isClose(rows[1].metrics.ascent ?? .nan, 491.74221024920655, within: 1e-9))
    let unnamed = itineraryWaypointRows(
      series, geometry: line,
      places: [
        ProfilePlace(
          .atDistance(id: "water", distance: 300),
          metrics: ItinerarySegmentRowMetrics(sectionDistance: 999))
      ])
    #expect(unnamed[0].metrics.sectionDistance == 300)
  }

  @Test("a place passed twice states its figures on its primary pass")
  func primary() {
    let loop: GeoJSONGeometry = .lineString(
      GeoJSONLineString(coordinates: [
        [6, 45, 1_000], [6, 45.005, 1_200], [6, 45.0075, 1_350], [6, 45.01, 1_500],
        [6, 45.0075, 1_350], [6, 45.005, 1_200], [6, 45, 1_000],
      ]))
    let rows = itineraryWaypointRows(
      buildElevationSeries(loop), geometry: loop,
      places: [
        ProfilePlace(.atPosition(id: "start", position: [6, 45]), name: "Start"),
        ProfilePlace(
          .atPosition(id: "spring", position: [6, 45.005]), name: "Spring",
          metrics: ItinerarySegmentRowMetrics(sectionDistance: 600)),
        ProfilePlace(.atPosition(id: "top", position: [6, 45.01]), name: "Top"),
        ProfilePlace(.atPosition(id: "finish", position: [6, 45]), name: "Finish"),
      ])
    #expect(rows.map(\.key) == ["start#0", "spring#0", "top#0", "spring#1", "finish#0"])
    #expect(rows[1].metrics.sectionDistance == 600 && rows[1].metrics.distance == 600)
    #expect(isClose(rows[3].metrics.sectionDistance ?? .nan, 555.974633222288, within: 1e-6))
  }

  @Test("an itinerary with no elevation states its distances alone")
  func flat() {
    let flatLine: GeoJSONGeometry = .lineString(
      GeoJSONLineString(coordinates: [[6, 45], [6, 45.005], [6, 45.01]]))
    let rows = itineraryWaypointRows(
      buildElevationSeries(flatLine), geometry: flatLine,
      places: [ProfilePlace(.atDistance(id: "hut", distance: 300), name: "Hut")])
    #expect(rows[0].metrics.altitude == nil && rows[0].metrics.ascent == nil)
    #expect(rows[0].metrics.distance == 300 && rows[0].metrics.sectionDistance == 300)
    #expect(itineraryWaypointRows(series, geometry: line, places: []).isEmpty)
  }
}
