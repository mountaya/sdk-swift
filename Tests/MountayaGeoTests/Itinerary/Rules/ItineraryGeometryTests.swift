import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("itineraryGeometry")
struct ItineraryGeometryTests {
  /// A chain read out of order profiles as another itinerary of the same length, which is the
  /// kind of wrong that draws cleanly.
  @Test("the chain is collected in position order, whatever order it arrived in")
  func chainOrder() throws {
    let second = lineString([6, 45.002, 1_200], [6, 45.003, 1_250])
    let first = lineString([6, 45, 1_000], [6, 45.001, 1_100])

    let geometry = itineraryGeometry([
      restSegment("b", position: 1, geojson: second), restSegment("a", position: 0, geojson: first),
    ])

    #expect(
      geometry == .geometryCollection(GeoJSONGeometryCollection(geometries: [first, second])))
  }

  @Test("each segment's geometry is kept as it stores it, a collection nested whole")
  func keptWhole() {
    let stored = collectionOf(
      lineString([6, 45], [6.01, 45]), .multiPoint(GeoJSONMultiPoint(coordinates: [[6, 45]])))

    let geometry = itineraryGeometry([restSegment("a", geojson: stored)])

    #expect(geometry == .geometryCollection(GeoJSONGeometryCollection(geometries: [stored])))
  }

  @Test("a segment with no geometry yet is left out")
  func skipsNone() {
    let line = lineString([6, 45, 1_000], [6, 45.001, 1_100])

    let geometry = itineraryGeometry([
      restSegment("a", position: 0), restSegment("b", position: 1, geojson: line),
    ])

    #expect(geometry == .geometryCollection(GeoJSONGeometryCollection(geometries: [line])))
  }

  /// An empty collection reads as an itinerary of no length; none draws the state a missing
  /// itinerary draws.
  @Test("no geometry is none, never an empty collection")
  func none() {
    #expect(itineraryGeometry([restSegment("a")]) == nil)
    #expect(itineraryGeometry([]) == nil)
  }

  @Test("the chain profiles as one curve, each leg laid after the one before")
  func profilesAsOneCurve() throws {
    let geometry = itineraryGeometry([
      restSegment("a", position: 0, geojson: lineString([6, 45, 1_000], [6, 45.001, 1_100])),
      restSegment("b", position: 1, geojson: lineString([6, 45.001, 1_100], [6, 45.002, 1_200])),
    ])

    let series = buildElevationSeries(geometry)

    #expect(series.points.map(\.elevation) == [1_000, 1_100, 1_100, 1_200])
    #expect(
      isClose(
        series.totalDistance, 2 * haversineMeters(from: [6, 45], to: [6, 45.001]), within: 1e-6))
  }
}
