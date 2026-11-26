import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("buildElevationSeries")
struct BuildElevationSeriesTests {
  @Test("each vertex is a sample of distance against altitude")
  func samplesOfTheLine() {
    let series = buildElevationSeries(.lineString(GeoJSONLineString(coordinates: climbLine)))
    #expect(series.points.count == 7)
    #expect(series.points.map(\.index) == [0, 1, 2, 3, 4, 5, 6])
    #expect(isClose(series.points[1].distance, 952.543779427426, within: 1e-6))
    #expect(series.points[1].lngLat == [6.8752, 45.9287])
    #expect(isClose(series.totalDistance, 7_117.508508284167, within: 1e-6))
    #expect(series.minElevation == 1_035)
    #expect(series.maxElevation == 1_480)
  }

  @Test("no geometry is an itinerary of no length")
  func noGeometry() {
    let series = buildElevationSeries(nil)
    #expect(!series.hasElevation)
    #expect(series.totalDistance == 0)
    #expect(series.minElevation == nil)
    #expect(series.maxElevation == nil)
  }

  /// The jump from one line to the next costs nothing; vias are no line.
  @Test("the lines are laid end to end, and the jump between them costs nothing")
  func endToEnd() {
    let first: [[Double]] = [[0, 0, 10], [1, 0, 20]]
    let second: [[Double]] = [[5, 0, 30], [6, 0, 40]]
    let series = buildElevationSeries(
      .geometryCollection(
        GeoJSONGeometryCollection(geometries: [
          .multiLineString(GeoJSONMultiLineString(coordinates: [first, second])),
          .multiPoint(GeoJSONMultiPoint(coordinates: [[9, 9]])),
        ])))
    #expect(
      areClose(
        series.points.map { $0.distance / metersPerDegreeMeanSphere }, [0, 1, 1, 2], within: 1e-12))
    #expect(isClose(series.totalDistance, 2 * metersPerDegreeMeanSphere, within: 1e-6))
  }

  @Test(
    "a vertex with no altitude advances the distance, and one that names no place is measured across"
  )
  func holes() {
    let series = buildElevationSeries(
      lineString([0, 0, 10], [1, 0], [.nan, 0, 99], [2, 0, .nan], [3, 0, 40]))
    #expect(
      areClose(
        series.points.map { $0.distance / metersPerDegreeMeanSphere }, [0, 3], within: 1e-12))
    #expect(series.points.map(\.elevation) == [10, 40])
    #expect(isClose(series.totalDistance, 3 * metersPerDegreeMeanSphere, within: 1e-6))
  }

  @Test("a series past its ceiling is thinned and keeps the whole line's range")
  func thinned() {
    let series = buildElevationSeries(
      .lineString(GeoJSONLineString(coordinates: climbLine)), maxPoints: 4)
    #expect(series.points.map(\.elevation) == [1_035, 1_118, 1_240, 1_252])
    #expect(series.maxElevation == 1_480)
    #expect(isClose(series.totalDistance, 7_117.508508284167, within: 1e-6))
    let overTheCeiling = buildElevationSeries(
      .lineString(
        GeoJSONLineString(
          coordinates: (0...maxProfilePoints).map { [Double($0) / 1_000, 45, Double($0)] })))
    #expect(overTheCeiling.points.count == maxProfilePoints)
    #expect(overTheCeiling.points.first?.elevation == 0)
    #expect(overTheCeiling.points.last?.elevation == Double(maxProfilePoints))
    #expect(maxProfilePoints == 500)
  }
}
