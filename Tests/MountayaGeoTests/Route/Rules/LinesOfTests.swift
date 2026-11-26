import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("linesOf")
struct LinesOfTests {
  private let first: [[Double]] = [[6, 45], [6.1, 45]]
  private let second: [[Double]] = [[7, 46], [7.1, 46]]

  @Test("every line is read in the order the geometry writes it")
  func order() {
    #expect(linesOf(.lineString(GeoJSONLineString(coordinates: first))) == [first])
    #expect(
      linesOf(.multiLineString(GeoJSONMultiLineString(coordinates: [first, second])))
        == [first, second])
    let collection = GeoJSONGeometry.geometryCollection(
      GeoJSONGeometryCollection(geometries: [
        .lineString(GeoJSONLineString(coordinates: first)),
        .multiPoint(GeoJSONMultiPoint(coordinates: [[6.05, 45]])),
        .geometryCollection(
          GeoJSONGeometryCollection(geometries: [
            .lineString(GeoJSONLineString(coordinates: second))
          ])),
      ]))
    #expect(linesOf(collection) == [first, second])
  }

  @Test("a point, a polygon or no geometry holds no line")
  func noLine() {
    #expect(linesOf(nil) == [])
    #expect(linesOf(.point(GeoJSONPoint(coordinates: [6, 45]))) == [])
    #expect(linesOf(.polygon(GeoJSONPolygon(coordinates: [first + [[6, 45]]]))) == [])
    #expect(linesOf(.multiPolygon(GeoJSONMultiPolygon(coordinates: [[first + [[6, 45]]]]))) == [])
  }
}
