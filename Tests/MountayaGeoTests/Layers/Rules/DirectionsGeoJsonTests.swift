import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("directionsGeoJson")
struct DirectionsGeoJsonTests {
  @Test("each route is a line carrying its metrics")
  func routes() throws {
    let line = GeoJSONGeometry.lineString(GeoJSONLineString(coordinates: [[0, 0], [1, 1]]))
    let routes = DataSchema.DirectionsResult {
      $0.routes = [
        DataSchema.DirectionsRoute {
          $0.distance = 1200
          $0.duration = 900
          $0.summary = "Via the col"
          $0.geometry = line
        },
        DataSchema.DirectionsRoute(),
      ]
    }
    let features = directionsGeoJson(routes).features
    try #require(features.count == 2)
    #expect(features[0].geometry == line)
    #expect(features[0].properties["summary"] == "Via the col")
    #expect(features[0].properties["distance"] == 1200)
    #expect(features[1].properties[featureKindProperty] == "directions")
    #expect(features[1].properties[featureIndexProperty] == 1)
    #expect(features[1].properties["summary"] == .null)
    #expect(features[1].geometry == nil)
  }
}
