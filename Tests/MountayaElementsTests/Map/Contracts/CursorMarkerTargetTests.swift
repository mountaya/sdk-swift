import Foundation
import MountayaClient
import Testing

@testable import MountayaElements

@Suite("CursorMarkerTarget")
@MainActor
struct CursorMarkerTargetTests {
  @Test("a map is a target its markers are pinned, edited and taken off through")
  func engine() throws {
    let map = MapEngine(
      client: try Mountaya(credential: .publishable(key: "pk_test_a")),
      geolocation: InertGeolocation())
    let target: any CursorMarkerTarget = map
    try target.addMarker(MapMarker(id: "a", position: [6, 45]))
    try target.editMarker("a", position: [7, 46], color: nil, glyph: nil, label: nil)
    #expect(map.state.markers.map(\.position) == [[7, 46]])
    #expect(throws: MapError.self) {
      try target.editMarker("b", position: [7, 46], color: nil, glyph: nil, label: nil)
    }
    target.removeMarker("a")
    #expect(map.state.markers.isEmpty)
  }
}
