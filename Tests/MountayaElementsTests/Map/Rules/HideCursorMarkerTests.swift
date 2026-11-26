import Testing

@testable import MountayaElements

@Suite("hideCursorMarker")
@MainActor
struct HideCursorMarkerTests {
  @Test("an element takes down the marker it added, and never one it did not")
  func hide() throws {
    let map = ShowCursorMarkerTests.Markers()
    try map.addMarker(MapMarker(id: "c", position: [6, 45], glyph: "map-pin"))
    hideCursorMarker(on: map, pinned: nil, id: "c")
    #expect(map.held["c"] != nil)
    hideCursorMarker(on: map, pinned: CursorMarkerPin(color: nil, glyph: "pin-filled"), id: "c")
    #expect(map.held["c"] == nil && map.writes.last == "remove")
  }
}
