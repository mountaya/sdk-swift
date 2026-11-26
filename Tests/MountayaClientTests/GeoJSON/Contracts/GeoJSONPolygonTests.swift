import Testing

@testable import MountayaClient

@Suite("GeoJSONPolygon")
struct GeoJSONPolygonTests {
  @Test("a `Polygon` reads its positions and is written back with its type")
  func roundTrip() throws {
    let geometry = try ScriptedSender.decode(
      GeoJSONPolygon.self,
      from: #"{"type": "Polygon", "coordinates": [[[0, 0], [1, 0], [1, 1], [0, 0]]]}"#
    )

    #expect(geometry == GeoJSONPolygon(coordinates: [[[0, 0], [1, 0], [1, 1], [0, 0]]]))
    #expect(
      try ScriptedSender.json(geometry)
        == #"{"coordinates":[[[0,0],[1,0],[1,1],[0,0]]],"type":"Polygon"}"#)
  }

  @Test("a geometry of another type is refused")
  func refusesAnotherType() {
    #expect(throws: DecodingError.self) {
      try ScriptedSender.decode(GeoJSONPolygon.self, from: #"{"type": "Point", "coordinates": []}"#)
    }
  }
}
