import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("ItineraryStroke")
struct ItineraryStrokeTests {
  @Test("two strokes are equal where they are the same stroke in the same colour, and hash alike")
  func equality() {
    #expect(ItineraryStroke.line(color: "#123456") == .line(color: "#123456"))
    #expect(
      ItineraryStroke.line(color: "#123456").hashValue
        == ItineraryStroke.line(color: "#123456").hashValue)
    #expect(ItineraryStroke.line(color: "#123456") != .dashed(color: "#123456"))
    #expect(ItineraryStroke.line(color: "#123456") != .line(color: "#654321"))
    #expect(ItineraryStroke.casing == .casing)
    #expect(ItineraryStroke.casing.hashValue == ItineraryStroke.casing.hashValue)
    #expect(ItineraryStroke.dashed(color: "#868e96") != .casing)
  }

  @Test("a colour read from the feature compares as the expression it is")
  func expression() {
    let read: JSONValue = ["get", "mtyaColor"]
    #expect(ItineraryStroke.line(color: read) == .line(color: ["get", "mtyaColor"]))
    #expect(
      ItineraryStroke.line(color: read).hashValue
        == ItineraryStroke.line(color: ["get", "mtyaColor"]).hashValue)
    #expect(ItineraryStroke.line(color: read) != .line(color: ["get", "color"]))
  }

  /// A colour compares as `sameJson` reads it: a number as the same number, a text by its scalars.
  @Test("a colour compares its numbers as the same numbers and its texts by scalars")
  func sameJson() {
    #expect(ItineraryStroke.dashed(color: .number(.nan)) == .dashed(color: .number(.nan)))
    #expect(ItineraryStroke.dashed(color: .number(0)) != .dashed(color: .number(-0.0)))
    #expect(ItineraryStroke.line(color: "caf\u{E9}") != .line(color: "cafe\u{301}"))
  }
}
