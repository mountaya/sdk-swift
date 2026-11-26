import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("GeoJSONFeatureCollection")
struct GeoJSONFeatureCollectionTests {
  @Test("two collections are equal where they hold the same features in order")
  func equality() {
    let a = GeoJSONFeature(geometry: nil, properties: [:])
    let b = GeoJSONFeature(geometry: nil, properties: ["mtyaIndex": 1])
    #expect(GeoJSONFeatureCollection(features: [a]) == GeoJSONFeatureCollection(features: [a]))
    #expect(GeoJSONFeatureCollection(features: [a]) != GeoJSONFeatureCollection(features: []))
    #expect(
      GeoJSONFeatureCollection(features: [a, b]) != GeoJSONFeatureCollection(features: [b, a]))
  }
}
