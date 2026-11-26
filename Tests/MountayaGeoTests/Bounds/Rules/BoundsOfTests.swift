import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("boundsOf")
struct BoundsOfTests {
  private func line(_ positions: [Double]...) -> GeoJSONGeometry {
    .lineString(GeoJSONLineString(coordinates: positions))
  }

  @Test("the box covers every position of every geometry")
  func everyGeometry() {
    #expect(
      boundsOf([line([6.86, 45.85], [6.9, 45.92], [6.88, 45.8])]) == [6.86, 45.8, 6.9, 45.92])
    #expect(
      boundsOf([
        .point(GeoJSONPoint(coordinates: [5, 45])),
        .multiLineString(GeoJSONMultiLineString(coordinates: [[[6, 44]], [[7, 46]]])),
        .polygon(GeoJSONPolygon(coordinates: [[[6, 45], [8, 45], [6, 47], [6, 45]]])),
      ]) == [5, 44, 8, 47])
    #expect(
      boundsOf([.multiPolygon(GeoJSONMultiPolygon(coordinates: [[[[1, 2], [3, 4]]]]))])
        == [1, 2, 3, 4])
  }

  /// A directions segment's collection holds its line and a MultiPoint of its vias, at any depth.
  @Test("a collection of any depth is flattened first")
  func nested() {
    let nested = GeoJSONGeometry.geometryCollection(
      GeoJSONGeometryCollection(geometries: [
        line([6.86, 45.85], [6.9, 45.92]),
        .geometryCollection(
          GeoJSONGeometryCollection(geometries: [
            .multiPoint(GeoJSONMultiPoint(coordinates: [[6.95, 45.7]]))
          ])),
      ]))
    #expect(boundsOf([nested]) == [6.86, 45.7, 6.95, 45.92])
  }

  @Test("a set straddling the antimeridian is framed across it")
  func straddling() {
    #expect(boundsOf([line([179.5, -16], [-179.5, -17])]) == [179.5, -17, 180.5, -16])
    let east = GeoJSONGeometry.polygon(
      GeoJSONPolygon(coordinates: [[[179, 1], [180, 1], [180, 2], [179, 1]]]))
    let west = GeoJSONGeometry.polygon(
      GeoJSONPolygon(coordinates: [[[-180, 1], [-179, 1], [-180, 2], [-180, 1]]]))
    #expect(boundsOf([east, west]) == [179, 1, 181, 2])
  }

  /// Positions alone cannot tell such a set from one drawn wider than half the world across the
  /// prime meridian, which reads the narrow way too.
  @Test("a set wider than half the world reads the narrow way")
  func widerThanHalf() {
    #expect(boundsOf([line([-170, 0], [170, 1])]) == [170, 0, 190, 1])
    #expect(boundsOf([line([-100, 0], [100, 1])]) == [100, 0, 260, 1])
    // Half a turn or less keeps its longitudes as written.
    #expect(boundsOf([line([-90, 0], [90, 1])]) == [-90, 0, 90, 1])
  }

  @Test("a set on the antimeridian keeps its written width")
  func onTheAntimeridian() {
    #expect(boundsOf([line([180, -10], [-180, 10])]) == [-180, -10, 180, 10])
    #expect(boundsOf([line([180, -10], [180, 10])]) == [180, -10, 180, 10])
  }

  /// A set written past the range keeps it; a turned frame past 180 is brought back by a turn.
  @Test("a set written past the range is read as written")
  func pastTheRange() {
    #expect(boundsOf([line([190, 0], [200, 1])]) == [190, 0, 200, 1])
    #expect(boundsOf([line([190, 0], [-170, 1])]) == [-170, 0, -170, 1])
  }

  @Test("a position that names no place bounds nothing")
  func noPlace() {
    #expect(
      boundsOf([line([6.86, 45.85], [6.9], [.nan, 50], [6.88, 45.8, 3000])])
        == [6.86, 45.8, 6.88, 45.85])
    #expect(boundsOf([line([6.9], [6, .infinity])]) == nil)
    #expect(boundsOf([]) == nil)
    #expect(boundsOf([.geometryCollection(GeoJSONGeometryCollection(geometries: []))]) == nil)
  }

  @Test("an edge is the first extreme value met, so of 0 and -0 the one written first")
  func signedZero() throws {
    let box = try #require(boundsOf([line([-0.0, 0], [0, -0.0])]))
    #expect(sameNumbers(box, [-0.0, 0, -0.0, 0]))
  }
}
