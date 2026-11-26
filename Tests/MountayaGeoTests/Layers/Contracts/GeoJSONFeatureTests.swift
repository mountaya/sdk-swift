import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("GeoJSONFeature")
struct GeoJSONFeatureTests {
  @Test("two features are equal where they hold the same geometry and properties, and hash alike")
  func equality() {
    let kind: [String: JSONValue] = ["mtyaKind": "poi"]
    let point = GeoJSONGeometry.point(GeoJSONPoint(coordinates: [6, 45]))
    #expect(
      GeoJSONFeature(geometry: point, properties: kind)
        == GeoJSONFeature(geometry: point, properties: kind))
    #expect(
      GeoJSONFeature(geometry: .point(GeoJSONPoint(coordinates: [0, 45])), properties: kind)
        != GeoJSONFeature(
          geometry: .point(GeoJSONPoint(coordinates: [-0.0, 45])), properties: kind))
    #expect(
      GeoJSONFeature(geometry: nil, properties: kind).hashValue
        == GeoJSONFeature(geometry: nil, properties: kind).hashValue)
    #expect(
      GeoJSONFeature(geometry: nil, properties: kind)
        != GeoJSONFeature(geometry: point, properties: kind))
  }

  /// The client's own `==` reads a NaN coordinate as differing from itself; a feature does not.
  @Test("two features compare their numbers as the same numbers")
  func sameNumbers() {
    let unplaced = GeoJSONGeometry.point(GeoJSONPoint(coordinates: [.nan, 45]))
    let width: [String: JSONValue] = ["mtyaWidth": .number(.nan)]
    #expect(
      GeoJSONFeature(geometry: unplaced, properties: width)
        == GeoJSONFeature(geometry: unplaced, properties: width))
    #expect(
      Set([
        GeoJSONFeature(geometry: unplaced, properties: width),
        GeoJSONFeature(geometry: unplaced, properties: width),
      ]).count == 1)
    #expect(
      GeoJSONFeature(geometry: nil, properties: ["value": 0])
        != GeoJSONFeature(geometry: nil, properties: ["value": .number(-0.0)]))
  }
}
