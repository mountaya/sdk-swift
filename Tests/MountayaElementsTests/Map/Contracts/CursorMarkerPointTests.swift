import Testing

@testable import MountayaElements

@Suite("CursorMarkerPoint")
struct CursorMarkerPointTests {
  @Test("a point is drawn with the filled pin in the map's own colour unless it names others")
  func defaults() {
    let point = CursorMarkerPoint(id: "mtya-profile-cursor", lngLat: [6.8652, 45.9237])
    #expect(point.glyph == "pin-filled" && point.color == nil)
  }

  @Test("two points are equal where every member is, positions by the same-number relation")
  func equality() {
    let point = CursorMarkerPoint(id: "a", lngLat: [6, 45], color: "#e8590c", glyph: "pin")
    #expect(point == CursorMarkerPoint(id: "a", lngLat: [6, 45], color: "#e8590c", glyph: "pin"))
    #expect(
      point.hashValue
        == CursorMarkerPoint(id: "a", lngLat: [6, 45], color: "#e8590c", glyph: "pin").hashValue)
    #expect(
      CursorMarkerPoint(id: "a", lngLat: [0, 45]) != CursorMarkerPoint(id: "a", lngLat: [-0.0, 45]))
    #expect(
      CursorMarkerPoint(id: "a", lngLat: [.nan, 45])
        == CursorMarkerPoint(id: "a", lngLat: [.nan, 45]))
  }
}
