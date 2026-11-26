import Testing

@testable import MountayaElements

@Suite("CursorMarkerPin")
struct CursorMarkerPinTests {
  @Test("two pins are equal where both are written alike, the map's own colour only to itself")
  func equality() {
    #expect(
      CursorMarkerPin(color: nil, glyph: "pin-filled")
        == CursorMarkerPin(color: nil, glyph: "pin-filled"))
    #expect(
      CursorMarkerPin(color: nil, glyph: "pin-filled")
        != CursorMarkerPin(color: "#e8590c", glyph: "pin-filled"))
    #expect(
      CursorMarkerPin(color: nil, glyph: "pin") != CursorMarkerPin(color: nil, glyph: "pin-filled"))
    #expect(
      CursorMarkerPin(color: "#fff", glyph: "pin").hashValue
        == CursorMarkerPin(color: "#fff", glyph: "pin").hashValue)
  }
}
