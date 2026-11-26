import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("matrixGeoJson")
struct MatrixGeoJsonTests {
  private let locations: [[Double]] = [[6, 45], [6.1, 45.1], [6.2, 45.2]]

  private func input(
    _ metrics: [DataSchema.MatrixMetric] = [.duration], sources: [Int]? = nil,
    destinations: [Int]? = nil
  ) -> DataSchema.MatrixInput {
    DataSchema.MatrixInput(activity: .hikingAndTrail, locations: locations, metrics: metrics) {
      $0.sources = sources
      $0.destinations = destinations
    }
  }

  @Test("each solved pair of distinct locations is a connector, then each location a point")
  func connectorsThenPoints() throws {
    let result = DataSchema.MatrixResult {
      $0.durations = [[0, 100, 300], [100, 0, nil], [300, 200, 0]]
    }
    let features = matrixGeoJson(input(), result: result).features
    try #require(features.count == 8)
    let connectors = features.prefix(5)
    #expect(
      connectors.map { $0.properties[featureWidthProperty] } == [1, 6, 1, 6, 3.5])
    #expect(
      connectors.last?.geometry
        == .lineString(GeoJSONLineString(coordinates: [locations[2], locations[1]])))
    #expect(features[5].properties[featureKindProperty] == "matrix-location")
    #expect(features[5].properties[featureIndexProperty] == 0)
    #expect(features[5].geometry == .point(GeoJSONPoint(coordinates: locations[0])))
  }

  /// A row is the location `sources` lists at its place, a column the one `destinations` lists.
  @Test("a subset grid draws from the locations it lists")
  func subset() throws {
    let result = DataSchema.MatrixResult {
      $0.distances = [[1000, 4000]]
      $0.durations = [[60, 240]]
    }
    let features = matrixGeoJson(
      input([.distance, .duration], sources: [1], destinations: [0, 2]), result: result
    ).features
    try #require(features.count == 5)
    #expect(features.prefix(2).map { $0.properties["value"] } == [1000, 4000])
    #expect(
      features[0].geometry
        == .lineString(GeoJSONLineString(coordinates: [locations[1], locations[0]])))
    #expect(features[0].properties["metric"] == "DISTANCE")
    #expect(features[0].properties["from"] == 1)
    #expect(features[0].properties["to"] == 0)
  }

  @Test("a grid with no spread draws at the least, and an unknown metric draws no connector")
  func edges() {
    let flat = DataSchema.MatrixResult { $0.durations = [[0, 50], [50, 0]] }
    let two = DataSchema.MatrixInput(
      activity: .running, locations: Array(locations.prefix(2)), metrics: [.duration])
    #expect(
      matrixGeoJson(two, result: flat).features.prefix(2).map {
        $0.properties[featureWidthProperty]
      } == [1, 1])
    let unknown = matrixGeoJson(
      input([DataSchema.MatrixMetric(rawValue: "ENERGY")]), result: flat
    ).features
    #expect(unknown.count == 3)
    // A cell that is no finite number is unsolved, and one whose location is out of the list
    // counts toward the extremes and draws nothing.
    let stray = DataSchema.MatrixResult { $0.durations = [[0, .infinity], [10, 0]] }
    let reaching = DataSchema.MatrixInput(
      activity: .running, locations: Array(locations.prefix(2)), metrics: [.duration]
    ) {
      $0.sources = [0, 5]
      $0.destinations = [0, 1]
    }
    let drawn = matrixGeoJson(reaching, result: stray).features
    #expect(drawn.count == 2)
    #expect(drawn.allSatisfy { $0.properties[featureKindProperty] == "matrix-location" })
  }

  @Test("a width is held within the scale")
  func width() {
    #expect(matrixLineWidth(.nan, min: 0, max: 1) == 1)
    #expect(matrixLineWidth(10, min: 0, max: 1) == 6)
    #expect(matrixLineWidth(-10, min: 0, max: 1) == 1)
    #expect(matrixLineWidth(5, min: 5, max: 5) == 1)
    #expect(matrixLineWidth(200, min: 100, max: 300) == 3.5)
    #expect(matrixLineWidth(1, min: 0, max: .infinity) == 1)
    #expect([matrixLineMinWidth, matrixLineMaxWidth] == [1, 6])
  }

  @Test("a width scales its cost linearly from the cheapest to the dearest of the grid")
  func scale() {
    #expect(matrixLineWidth(0, min: 0, max: 100) == 1)
    #expect(matrixLineWidth(25, min: 0, max: 100) == 2.25)
    #expect(matrixLineWidth(50, min: 0, max: 100) == 3.5)
    #expect(matrixLineWidth(100, min: 0, max: 100) == 6)
    // One past each end, so the hold is pinned at its edge.
    #expect(matrixLineWidth(101, min: 0, max: 100) == 6)
    #expect(matrixLineWidth(-1, min: 0, max: 100) == 1)
  }

  /// An infinite bound divides infinity by infinity, which no hold can turn back into a number.
  @Test("bounds out of order, and a bound or a cost of no finite number, draw at the least")
  func least() {
    #expect(matrixLineWidth(5, min: 20, max: 10) == 1)
    #expect(matrixLineWidth(5, min: -.infinity, max: 0) == 1)
    #expect(matrixLineWidth(5, min: 0, max: .nan) == 1)
    #expect(matrixLineWidth(5, min: .nan, max: 100) == 1)
    #expect(matrixLineWidth(.infinity, min: 0, max: 100) == 1)
    #expect(matrixLineWidth(-.infinity, min: 0, max: 100) == 1)
  }

  /// IEEE reads 0 and -0 as one number, so a grid from -0 to 0 has no spread.
  @Test("a negative zero is a cost and a bound like zero")
  func negativeZero() {
    #expect(matrixLineWidth(0, min: -0.0, max: 0) == 1)
    #expect(matrixLineWidth(-0.0, min: 0, max: 100) == 1)
    #expect(matrixLineWidth(50, min: -0.0, max: 100) == 3.5)
  }
}
