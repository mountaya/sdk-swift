import Testing

@testable import MountayaClient

@Suite("GeoJSONLineString")
struct GeoJSONLineStringTests {
  @Test("a `LineString` reads its positions and is written back with its type")
  func roundTrip() throws {
    let geometry = try ScriptedSender.decode(
      GeoJSONLineString.self,
      from: #"{"type": "LineString", "coordinates": [[6.86, 45.83], [6.87, 45.84]]}"#
    )

    #expect(geometry == GeoJSONLineString(coordinates: [[6.86, 45.83], [6.87, 45.84]]))
    #expect(
      try ScriptedSender.json(geometry)
        == #"{"coordinates":[[6.86,45.83],[6.87,45.84]],"type":"LineString"}"#)
  }

  @Test("a geometry of another type is refused")
  func refusesAnotherType() {
    #expect(throws: DecodingError.self) {
      try ScriptedSender.decode(
        GeoJSONLineString.self, from: #"{"type": "Point", "coordinates": []}"#)
    }
  }
}
