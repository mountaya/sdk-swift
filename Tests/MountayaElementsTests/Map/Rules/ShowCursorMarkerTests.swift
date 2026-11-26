import MountayaGeo
import Testing

@testable import MountayaElements

@Suite("showCursorMarker")
@MainActor
struct ShowCursorMarkerTests {
  /// Markers is a map recording each write it took, as the elements' fixtures do.
  final class Markers: CursorMarkerTarget {
    var held: [String: MapMarker] = [:]
    var writes: [String] = []

    func addMarker(_ marker: MapMarker) throws(MapError) {
      held[marker.id] = marker
      writes.append("add \(marker.color ?? "own") \(marker.glyph ?? "dot") \(marker.position)")
    }

    func editMarker(
      _ id: String, position: [Double]?, color: String?, glyph: String?, label: String?
    ) throws(MapError) {
      guard var marker = held[id] else { throw MapError(kind: .markerNotFound, name: id) }
      marker.position = position ?? marker.position
      held[id] = marker
      writes.append("edit \(marker.position)")
    }

    func removeMarker(_ id: String) {
      held[id] = nil
      writes.append("remove")
    }
  }

  @Test("the glyph and the three ids are the contract's")
  func constants() {
    #expect(cursorMarkerGlyph == "pin-filled")
    #expect(profileCursorMarkerId == "mtya-profile-cursor")
    #expect(segmentTableCursorMarkerId == "mtya-segment-table-cursor")
    #expect(waypointTableCursorMarkerId == "mtya-waypoint-table-cursor")
  }

  @Test("on a map drawing the bundled marker set the filled pin is the pin's dot (C40)")
  func dot() {
    #expect(GlyphSet.control.markup[cursorMarkerGlyph] != nil)
    #expect(GlyphSet.marker.markup[cursorMarkerGlyph] == nil)
    #expect(
      describeMarkerPin(color: nil, glyph: cursorMarkerGlyph, in: .marker)
        == describeMarkerPin(color: nil, glyph: nil, in: .marker))
  }

  @Test("a cursor is added once, then moved by editing its position")
  func moved() throws {
    let map = Markers()
    var pinned = try showCursorMarker(
      on: map, pinned: nil, point: CursorMarkerPoint(id: "c", lngLat: [6, 45, 1_200]))
    pinned = try showCursorMarker(
      on: map, pinned: pinned, point: CursorMarkerPoint(id: "c", lngLat: [7, 46]))
    #expect(map.writes == ["add own pin-filled [6.0, 45.0]", "edit [7.0, 46.0]"])
    #expect(pinned == CursorMarkerPin(color: nil, glyph: "pin-filled"))
  }

  @Test("a change of colour or glyph, and a marker taken down elsewhere, add it again")
  func addedAgain() throws {
    let map = Markers()
    var pinned = try showCursorMarker(
      on: map, pinned: nil, point: CursorMarkerPoint(id: "c", lngLat: [6, 45]))
    pinned = try showCursorMarker(
      on: map, pinned: pinned, point: CursorMarkerPoint(id: "c", lngLat: [6, 45], color: "#e8590c"))
    map.removeMarker("c")
    pinned = try showCursorMarker(
      on: map, pinned: pinned, point: CursorMarkerPoint(id: "c", lngLat: [7, 46], color: "#e8590c"))
    #expect(
      map.writes == [
        "add own pin-filled [6.0, 45.0]", "add #e8590c pin-filled [6.0, 45.0]", "remove",
        "add #e8590c pin-filled [7.0, 46.0]",
      ])
    #expect(pinned.color == "#e8590c")
  }

  @Test("a refusal other than a missing marker is the map's own")
  func refused() {
    #expect(throws: MapError.self) {
      try showCursorMarker(
        on: MapEngineDouble(), pinned: nil, point: CursorMarkerPoint(id: "c", lngLat: [6, 95]))
    }
  }

  /// MapEngineDouble refuses every position, as a map refuses a latitude past the poles.
  final class MapEngineDouble: CursorMarkerTarget {
    func addMarker(_ marker: MapMarker) throws(MapError) {
      throw MapError(kind: .positionRefused, name: marker.id)
    }
    func editMarker(
      _ id: String, position: [Double]?, color: String?, glyph: String?, label: String?
    ) throws(MapError) {
      throw MapError(kind: .positionRefused, name: id)
    }
    func removeMarker(_ id: String) {}
  }
}
