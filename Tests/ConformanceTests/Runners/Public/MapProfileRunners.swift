import Foundation
import GateSupport
import MountayaClient
import MountayaElements
import MountayaGeo

extension PublicRunners {
  /// mapProfileCursorMarker plays the case's steps over a real map: each element, a profile and
  /// two tables, pins its cursor through `showCursorMarker(on:pinned:point:)` and takes it down
  /// through `hideCursorMarker(on:pinned:id:)`, holding what it pinned, and writes through a map
  /// that records each write the engine took, an edit the engine refused writing nothing. `remove`
  /// and `pin` are another holder of the id, writing to the engine directly. The glyph and the ids
  /// are held to the published constants.
  static let mapProfileCursorMarker = Runner(id: "map.profile.cursor-marker", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants(
      [:],
      values: [
        "glyph": .string(cursorMarkerGlyph),
        "markerIds": ProfileJSON.object([
          "profile": .string(profileCursorMarkerId),
          "segmentTable": .string(segmentTableCursorMarkerId),
          "waypointTable": .string(waypointTableCursorMarkerId),
        ]),
      ])
    let steps = try fixtureCase.input.array(at: "steps")
    return try await MainActor.run { () throws -> RunnerOutcome in
      let map = MapEngine(client: try MapFixtures.client(), geolocation: InertGeolocation())
      let recorder = RecordedMarkers(map: map)
      var elements: [String: CursorElement] = [:]
      let ids = [
        "profile": profileCursorMarkerId, "segmentTable": segmentTableCursorMarkerId,
        "waypointTable": waypointTableCursorMarkerId,
      ]
      for step in steps {
        let kind = try step.string(at: "step")
        if kind == "remove" {
          map.removeMarker(try step.string(at: "id"))
          continue
        }
        if kind == "pin" {
          try map.addMarker(
            MapMarker(
              id: try step.string(at: "id"), position: try step.numbers(at: "lngLat"),
              glyph: "map-pin"))
          continue
        }
        let name = try step.string(at: "element")
        guard let id = ids[name] else { throw FixtureError(description: "`\(name)` is no element") }
        var element = elements[name] ?? CursorElement(id: id)
        recorder.element = name
        switch kind {
        case "point":
          element.cursor = try step.numbers(at: "lngLat")
          try element.show(on: recorder)
        case "style":
          if let color = try step.optionalString(at: "color") { element.color = color }
          if let glyph = try step.optionalString(at: "glyph") { element.glyph = glyph }
          if element.cursor != nil { try element.show(on: recorder) }
        case "leave", "unmount":
          element.cursor = nil
          hideCursorMarker(on: recorder, pinned: element.pinned, id: element.id)
          element.pinned = nil
        default:
          throw FixtureError(description: "`\(kind)` is no step")
        }
        elements[name] = element
      }
      return .value(
        ProfileJSON.object([
          "markers": .array(
            map.state.markers.map { marker in
              ProfileJSON.object([
                "color": GeoProfileFixtures.text(marker.color),
                "glyph": GeoProfileFixtures.text(marker.glyph), "id": .string(marker.id),
                "lngLat": GeoFixtures.numbers(marker.position),
              ])
            }),
          "writes": .array(recorder.writes),
        ]))
    }
  }

  /// mapProfileEmphasis plays the case's steps over a real map: each element lights the stretch of
  /// the case's `series` between the leg's ends, `lineBetween(_:from:to:)`, through
  /// `writeLegEmphasis(on:isLit:stretch:color:)`, holding whether it lit the slot, and a step that
  /// points at none, or an element going, writes none. Each write is recorded as the element made
  /// it, and the slot is read off the map at the end, its colour null where it is the slot's own.
  static let mapProfileEmphasis = Runner(id: "map.profile.emphasis", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    let series = try GeoProfileFixtures.series(input["series"])
    let steps = try input.array(at: "steps")
    return try await MainActor.run { () throws -> RunnerOutcome in
      let map = MapEngine(client: try MapFixtures.client(), geolocation: InertGeolocation())
      let own = map.geometry(in: .emphasis).color
      let recorder = RecordedEmphasis(map: map)
      var lit: [String: Bool] = [:]
      for step in steps {
        let name = try step.string(at: "element")
        recorder.element = name
        var stretch: GeoJSONGeometry?
        var color: String?
        switch try step.string(at: "step") {
        case "point":
          stretch = lineBetween(
            series.points, from: try step.number(at: "from"), to: try step.number(at: "to"))
          color = try step.optionalString(at: "color")
        case "leave", "unmount":
          stretch = nil
        case let kind:
          throw FixtureError(description: "`\(kind)` is no step")
        }
        lit[name] = writeLegEmphasis(
          on: recorder, isLit: lit[name] ?? false, stretch: stretch, color: color)
      }
      let held = map.geometry(in: .emphasis)
      return .value(
        ProfileJSON.object([
          "slot": held.geometry.map {
            ProfileJSON.object([
              "color": held.color == own ? .null : .string(held.color),
              "geometry": GeoFixtures.written($0),
            ])
          } ?? .null,
          "writes": .array(recorder.writes),
        ]))
    }
  }
}

/// CursorElement is one element's cursor in a script of `map.profile.cursor-marker`: its marker's
/// id, where its cursor stands, how its marker is drawn, and what it pinned.
@MainActor
private struct CursorElement {
  let id: String
  var cursor: [Double]?
  var color: String?
  var glyph = cursorMarkerGlyph
  var pinned: CursorMarkerPin?

  init(id: String) {
    self.id = id
  }

  /// show pins the marker where the cursor stands.
  mutating func show(on map: some CursorMarkerTarget) throws(MapError) {
    guard let cursor else { return }
    pinned = try showCursorMarker(
      on: map, pinned: pinned,
      point: CursorMarkerPoint(id: id, lngLat: cursor, color: color, glyph: glyph))
  }
}

/// RecordedMarkers is a map that hands each marker write to a real engine and records the ones it
/// took, under the element writing them.
@MainActor
private final class RecordedMarkers: CursorMarkerTarget {
  let map: MapEngine
  var element = ""
  var writes: [OrderedJSON] = []

  init(map: MapEngine) {
    self.map = map
  }

  func addMarker(_ marker: MapMarker) throws(MapError) {
    try map.addMarker(marker)
    writes.append(
      ProfileJSON.object([
        "color": GeoProfileFixtures.text(marker.color), "element": .string(element),
        "glyph": GeoProfileFixtures.text(marker.glyph), "id": .string(marker.id),
        "lngLat": GeoFixtures.numbers(marker.position), "write": .string("add"),
      ]))
  }

  func editMarker(
    _ id: String, position: [Double]?, color: String?, glyph: String?, label: String?
  ) throws(MapError) {
    try map.editMarker(id, position: position, color: color, glyph: glyph, label: label)
    writes.append(
      ProfileJSON.object([
        "element": .string(element), "id": .string(id),
        "lngLat": position.map(GeoFixtures.numbers) ?? .null, "write": .string("edit"),
      ]))
  }

  func removeMarker(_ id: String) {
    map.removeMarker(id)
    writes.append(
      ProfileJSON.object([
        "element": .string(element), "id": .string(id), "write": .string("remove"),
      ]))
  }
}

/// RecordedEmphasis is a map that hands each emphasis write to a real engine and records it, under
/// the element writing it.
@MainActor
private final class RecordedEmphasis: LegEmphasisTarget {
  let map: MapEngine
  var element = ""
  var writes: [OrderedJSON] = []

  init(map: MapEngine) {
    self.map = map
  }

  func setGeometry(_ geometry: GeoJSONGeometry?, in slot: GeometrySlot, color: String?) {
    map.setGeometry(geometry, in: slot, color: color)
    writes.append(
      ProfileJSON.object([
        "color": GeoProfileFixtures.text(color), "element": .string(element),
        "geometry": geometry.map(GeoFixtures.written) ?? .null, "write": .string("set"),
      ]))
  }

  func clearGeometry(in slot: GeometrySlot) {
    map.clearGeometry(in: slot)
    writes.append(ProfileJSON.object(["element": .string(element), "write": .string("clear")]))
  }
}
