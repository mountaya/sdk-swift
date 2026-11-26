import Testing

@testable import MountayaClient

@Suite("GeoJSONMultiPoint")
struct GeoJSONMultiPointTests {
  @Test("a `MultiPoint` reads its positions and is written back with its type")
  func roundTrip() throws {
    let geometry = try ScriptedSender.decode(
      GeoJSONMultiPoint.self,
      from: #"{"type": "MultiPoint", "coordinates": [[6.86, 45.83], [6.87, 45.84]]}"#
    )

    #expect(geometry == GeoJSONMultiPoint(coordinates: [[6.86, 45.83], [6.87, 45.84]]))
    #expect(
      try ScriptedSender.json(geometry)
        == #"{"coordinates":[[6.86,45.83],[6.87,45.84]],"type":"MultiPoint"}"#)
  }

  @Test("a geometry of another type is refused")
  func refusesAnotherType() {
    #expect(throws: DecodingError.self) {
      try ScriptedSender.decode(
        GeoJSONMultiPoint.self, from: #"{"type": "Point", "coordinates": []}"#)
    }
  }
}
