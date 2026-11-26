import Foundation
import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("placeOnCurve")
struct PlaceOnCurveTests {
  private let series = ElevationSeries(
    points: samplesEvery100Meters(1_000, 1_100, 1_200, 1_300, 1_400, 1_500), totalDistance: 500,
    minElevation: 1_000, maxElevation: 1_500)
  private let domain = ElevationDomain(min: 1_000, max: 1_500)
  private let whole = ProfileRange(from: 0, to: 500)
  private let gateCutoff = Date(timeIntervalSince1970: 1_788_000_000)

  @Test("each pass is a pin, a divider or a cut-off by what it states")
  func kinds() {
    let places = [
      ProfilePlace(.atDistance(id: "start", distance: 100), name: "Start", isPinned: false),
      ProfilePlace(.atDistance(id: "water", distance: 200)),
      ProfilePlace(
        .atDistance(id: "gate", distance: 300), name: "Gate",
        details: WaypointDetails(timing: WaypointDetails.Timing(cutoffAt: gateCutoff))),
    ]
    let placement = placeOnCurve(
      series, geometry: nil, domain: domain, window: whole, places: places)
    #expect(placement.pins.map(\.key) == ["water#0", "gate#0"])
    #expect(placement.pins.map(\.x) == [40, 60] && placement.pins.map(\.y) == [60, 42])
    #expect(placement.pins.map(\.altitude) == [1_200, 1_300])
    #expect(placement.dividers.map(\.key) == ["start#0", "gate#0"])
    #expect(placement.dividers.map(\.y) == [78, 42])
    #expect(placement.cutoffs.map(\.key) == ["gate#0"] && placement.cutoffs.first?.x == 60)
    #expect(placement.cutoffs.first?.cutoffAt == gateCutoff)
  }

  @Test("a pin between two samples stands on the line between them")
  func between() {
    let placement = placeOnCurve(
      series, geometry: nil, domain: domain, window: whole,
      places: [ProfilePlace(.atDistance(id: "col", distance: 250), name: "Col")])
    #expect(placement.pins.first?.altitude == 1_250 && placement.pins.first?.y == 51)
  }

  @Test("a window leaves out what stands outside it, its ends kept")
  func window() {
    let places = ["before": 100.0, "edge": 200, "inside": 300, "after": 450].sorted {
      $0.value < $1.value
    }
    .map { ProfilePlace(.atDistance(id: $0.key, distance: $0.value), name: $0.key) }
    let placement = placeOnCurve(
      series, geometry: nil, domain: domain, window: ProfileRange(from: 200, to: 400),
      places: places)
    #expect(placement.pins.map(\.key) == ["edge#0", "inside#0"])
    #expect(placement.pins.map(\.x) == [0, 50])
  }

  @Test("with no elevation there is no pin, the divider has no height and the cut-off stands")
  func flat() {
    let flat = ElevationSeries(points: [], totalDistance: 500, minElevation: nil, maxElevation: nil)
    let gate = ProfilePlace(
      .atDistance(id: "gate", distance: 250), name: "Gate",
      details: WaypointDetails(timing: WaypointDetails.Timing(cutoffAt: gateCutoff)))
    let placement = placeOnCurve(
      flat, geometry: nil, domain: emptyElevationDomain, window: whole, places: [gate])
    #expect(placement.pins.isEmpty)
    #expect(placement.dividers.count == 1 && placement.dividers.first?.y == nil)
    #expect(placement.cutoffs.first?.x == 50)
  }

  @Test("a place passed twice is placed at each pass, keyed by its passes")
  func twice() {
    let line: GeoJSONGeometry = .lineString(
      GeoJSONLineString(coordinates: [
        [6, 45, 1_000], [6, 45.002, 1_200], [6, 45.004, 1_400], [6, 45.002, 1_200], [6, 45, 1_000],
      ]))
    let looped = buildElevationSeries(line)
    let hut = ProfilePlace(.atPosition(id: "hut", position: [6, 45.001]), name: "Hut")
    let placement = placeOnCurve(
      looped, geometry: line, domain: domain,
      window: ProfileRange(from: 0, to: looped.totalDistance), places: [hut])
    #expect(placement.dividers.map(\.key) == ["hut#0", "hut#1"])
    #expect(areClose(placement.dividers.map(\.x), [12.5, 87.5], within: 0.001))
    #expect(placement.pins.count == 2)
  }
}
