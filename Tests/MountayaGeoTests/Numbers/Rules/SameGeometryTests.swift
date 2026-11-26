import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("sameGeometry")
struct SameGeometryTests {
  @Test("two geometries are the same where they are of one type holding the same numbers")
  func same() {
    let line = GeoJSONGeometry.lineString(GeoJSONLineString(coordinates: [[0, 0], [.nan, 1]]))
    let copy = GeoJSONGeometry.lineString(GeoJSONLineString(coordinates: [[0, 0], [.nan, 1]]))
    #expect(sameGeometry(line, copy))
    // The client's own `==` reads a NaN coordinate as differing from itself in a fresh copy.
    #expect(line != copy)
    #expect(
      !sameGeometry(
        .point(GeoJSONPoint(coordinates: [0, 45])), .point(GeoJSONPoint(coordinates: [-0.0, 45]))))
    #expect(
      !sameGeometry(
        .point(GeoJSONPoint(coordinates: [0, 45])),
        .multiPoint(GeoJSONMultiPoint(coordinates: [[0, 45]]))))
    #expect(
      !sameGeometry(
        .point(GeoJSONPoint(coordinates: [0, 45])),
        .point(GeoJSONPoint(coordinates: [0, 45], bbox: [0, 45, 0, 45]))))
    let collection = GeoJSONGeometry.geometryCollection(
      GeoJSONGeometryCollection(geometries: [
        line, .polygon(GeoJSONPolygon(coordinates: [[[0, 0], [1, 0], [0, 0]]])),
        .multiPolygon(GeoJSONMultiPolygon(coordinates: [[[[0, 0], [1, 1], [0, 0]]]])),
        .multiLineString(GeoJSONMultiLineString(coordinates: [[[0, 0], [1, 1]]])),
      ]))
    #expect(sameGeometry(collection, collection))
    #expect(sameGeometry(nil, nil))
    #expect(!sameGeometry(nil, line))
  }

  @Test("two geometries it calls the same hash alike")
  func hashing() {
    var first = Hasher()
    first.combine(sameGeometry: .point(GeoJSONPoint(coordinates: [.nan, 45])))
    var second = Hasher()
    second.combine(sameGeometry: .point(GeoJSONPoint(coordinates: [.nan, 45])))
    #expect(first.finalize() == second.finalize())
  }

  @Test("two lines and two boxes are compared as the same numbers in order")
  func lists() {
    #expect(samePositions([[0, .nan]], [[0, .nan]]))
    #expect(!samePositions([[0, 1]], [[1, 0]]))
    #expect(samePositions(nil, nil))
    #expect(!samePositions(nil, []))
    #expect(sameBox([1, 2], [1, 2]))
    #expect(!sameBox(nil, [1]))
  }
}
