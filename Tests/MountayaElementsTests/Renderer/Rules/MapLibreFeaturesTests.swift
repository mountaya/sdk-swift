import MountayaClient
import MountayaGeo
import Testing

@testable import MountayaElements

@Suite("mapLibreFeatures")
struct MapLibreFeaturesTests {
  /// line is a LineString from 6.8, 45.8 to 6.9, 45.9, its positions carrying an elevation.
  private static let line = GeoJSONGeometry.lineString(
    GeoJSONLineString(coordinates: [[6.8, 45.8, 1020], [6.9, 45.9, 1100]]))
  /// ends is a MultiPoint of the two ends of `line`.
  private static let ends = GeoJSONGeometry.multiPoint(
    GeoJSONMultiPoint(coordinates: [[6.8, 45.8], [6.9, 45.9]]))

  @Test(
    "a segment's GeometryCollection is handed as one feature per geometry it holds, each with the feature's properties"
  )
  func segment() {
    let segment = GeoJSONFeature(
      geometry: .geometryCollection(GeoJSONGeometryCollection(geometries: [Self.line, Self.ends])),
      properties: ["color": "#2f80ed"])

    #expect(
      mapLibreFeatures([segment]) == [
        GeoJSONFeature(geometry: Self.line, properties: ["color": "#2f80ed"]),
        GeoJSONFeature(geometry: Self.ends, properties: ["color": "#2f80ed"]),
      ])
  }

  @Test(
    "a GeometryCollection held in another is read in turn, the features around it kept in their order, and one holding nothing hands nothing"
  )
  func nested() {
    let point = GeoJSONFeature(
      geometry: .point(GeoJSONPoint(coordinates: [6.86, 45.83])), properties: [:])
    let nested = GeoJSONFeature(
      geometry: .geometryCollection(
        GeoJSONGeometryCollection(geometries: [
          .geometryCollection(GeoJSONGeometryCollection(geometries: [Self.line])), Self.ends,
        ])),
      properties: ["rank": 1])
    let empty = GeoJSONFeature(
      geometry: .geometryCollection(GeoJSONGeometryCollection(geometries: [])), properties: [:])

    #expect(
      mapLibreFeatures([point, nested, empty, point]) == [
        point,
        GeoJSONFeature(geometry: Self.line, properties: ["rank": 1]),
        GeoJSONFeature(geometry: Self.ends, properties: ["rank": 1]),
        point,
      ])
  }

  @Test("features holding no GeometryCollection are handed as they are")
  func unchanged() {
    let features = [
      GeoJSONFeature(geometry: Self.line, properties: ["name": "Sentier"]),
      GeoJSONFeature(geometry: nil, properties: [:]),
    ]

    #expect(mapLibreFeatures(features) == features)
    #expect(mapLibreFeatures([]).isEmpty)
  }
}
