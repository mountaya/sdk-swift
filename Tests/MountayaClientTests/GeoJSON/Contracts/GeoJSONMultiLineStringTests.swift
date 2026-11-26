import Testing

@testable import MountayaClient

@Suite("GeoJSONMultiLineString")
struct GeoJSONMultiLineStringTests {
  @Test("a `MultiLineString` reads its positions and is written back with its type")
  func roundTrip() throws {
    let geometry = try ScriptedSender.decode(
      GeoJSONMultiLineString.self,
      from: #"{"type": "MultiLineString", "coordinates": [[[6.86, 45.83], [6.87, 45.84]]]}"#
    )

    #expect(geometry == GeoJSONMultiLineString(coordinates: [[[6.86, 45.83], [6.87, 45.84]]]))
    #expect(
      try ScriptedSender.json(geometry)
        == #"{"coordinates":[[[6.86,45.83],[6.87,45.84]]],"type":"MultiLineString"}"#)
  }

  @Test("a geometry of another type is refused")
  func refusesAnotherType() {
    #expect(throws: DecodingError.self) {
      try ScriptedSender.decode(
        GeoJSONMultiLineString.self, from: #"{"type": "Point", "coordinates": []}"#)
    }
  }
}
