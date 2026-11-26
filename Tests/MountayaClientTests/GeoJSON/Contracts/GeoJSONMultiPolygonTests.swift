import Testing

@testable import MountayaClient

@Suite("GeoJSONMultiPolygon")
struct GeoJSONMultiPolygonTests {
  @Test("a `MultiPolygon` reads its positions and is written back with its type")
  func roundTrip() throws {
    let geometry = try ScriptedSender.decode(
      GeoJSONMultiPolygon.self,
      from: #"{"type": "MultiPolygon", "coordinates": [[[[0, 0], [1, 0], [1, 1], [0, 0]]]]}"#
    )

    #expect(geometry == GeoJSONMultiPolygon(coordinates: [[[[0, 0], [1, 0], [1, 1], [0, 0]]]]))
    #expect(
      try ScriptedSender.json(geometry)
        == #"{"coordinates":[[[[0,0],[1,0],[1,1],[0,0]]]],"type":"MultiPolygon"}"#)
  }

  @Test("a geometry of another type is refused")
  func refusesAnotherType() {
    #expect(throws: DecodingError.self) {
      try ScriptedSender.decode(
        GeoJSONMultiPolygon.self, from: #"{"type": "Point", "coordinates": []}"#)
    }
  }
}
