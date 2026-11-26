import Testing

@testable import MountayaClient

@Suite("GeoJSONGeometry")
struct GeoJSONGeometryTests {
  @Test("a geometry decodes as the case its type names, with its bounding box")
  func dispatch() throws {
    let line = try ScriptedSender.decode(
      GeoJSONGeometry.self,
      from: #"{"type": "LineString", "coordinates": [[1, 2], [3, 4]], "bbox": [1, 2, 3, 4]}"#
    )

    #expect(
      line == .lineString(GeoJSONLineString(coordinates: [[1, 2], [3, 4]], bbox: [1, 2, 3, 4])))
    #expect(
      try ScriptedSender.json(line)
        == #"{"bbox":[1,2,3,4],"coordinates":[[1,2],[3,4]],"type":"LineString"}"#
    )
  }

  @Test("a type RFC 7946 does not define is refused, since the set is closed")
  func closed() {
    for type in ["Feature", "FeatureCollection", "point"] {
      #expect(throws: DecodingError.self) {
        try ScriptedSender.decode(
          GeoJSONGeometry.self, from: #"{"type": "\#(type)", "coordinates": []}"#)
      }
    }
  }
}
