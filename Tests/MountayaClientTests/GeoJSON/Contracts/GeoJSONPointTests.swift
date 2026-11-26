import Testing

@testable import MountayaClient

@Suite("GeoJSONPoint")
struct GeoJSONPointTests {
  @Test("a `Point` reads its positions and is written back with its type")
  func roundTrip() throws {
    let geometry = try ScriptedSender.decode(
      GeoJSONPoint.self,
      from: #"{"type": "Point", "coordinates": [6.86, 45.83, 1035]}"#
    )

    #expect(geometry == GeoJSONPoint(coordinates: [6.86, 45.83, 1035]))
    #expect(
      try ScriptedSender.json(geometry) == #"{"coordinates":[6.86,45.83,1035],"type":"Point"}"#)
  }

  @Test("a geometry of another type is refused")
  func refusesAnotherType() {
    #expect(throws: DecodingError.self) {
      try ScriptedSender.decode(
        GeoJSONPoint.self, from: #"{"type": "LineString", "coordinates": []}"#)
    }
  }
}
