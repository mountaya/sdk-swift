import Testing

@testable import MountayaClient

@Suite("GeoJSONGeometryCollection")
struct GeoJSONGeometryCollectionTests {
  @Test("a collection reads each member as the geometry its type names")
  func members() throws {
    let collection = try ScriptedSender.decode(
      GeoJSONGeometryCollection.self,
      from:
        #"{"type": "GeometryCollection", "geometries": [{"type": "Point", "coordinates": [1, 2]}]}"#
    )

    #expect(collection.geometries == [.point(GeoJSONPoint(coordinates: [1, 2]))])
    #expect(collection.bbox == nil)
  }
}
