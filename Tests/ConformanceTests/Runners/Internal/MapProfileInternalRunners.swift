import Foundation
import GateSupport
import MountayaClient
import MountayaGeo

@testable import MountayaElements

extension InternalRunners {
  /// mapProfileTableRows plays the case's steps over an itinerary's two tables beside a real map,
  /// through the rules `ItinerarySegmentTable` and `ItineraryWaypointTable` draw by: a row pointed
  /// at writes the target `segmentRowTarget(_:series:)` or `waypointRowTarget(_:series:)` answers,
  /// each table pinning its cursor under its own id and lighting the emphasis slot as a table's link
  /// writes them (`TableLink`); `hover` is the map's hover over features naming the case's leg, read
  /// by `hoveredLeg(_:)`; and `highlight` is the row the app names. Each step answers the markers
  /// the map holds, the stretch its emphasis slot holds, and the rows lit, a segment row lit as
  /// `isSegmentRowLit(_:pointed:highlighted:hovered:)` says and a waypoint row where it is pointed
  /// at.
  static let mapProfileTableRows = Runner(id: "map.profile.table-rows", table: .internal) {
    fixture, fixtureCase in
    try fixture.holdConstants([:])
    let input = fixtureCase.input
    let series = try GeoProfileFixtures.series(input["series"])
    var segments: [ItinerarySegmentRow] = []
    for (index, row) in (input["segments"] == nil ? [] : try input.array(at: "segments"))
      .enumerated()
    {
      let id = try row.string(at: "id")
      segments.append(
        ItinerarySegmentRow(
          key: id, id: id, memberIds: try ProfileModelJSON.optionalTexts(row["memberIds"]),
          name: id, index: index, from: try row.number(at: "from"), to: try row.number(at: "to"),
          metrics: ItinerarySegmentRowMetrics()))
    }
    var waypoints: [ItineraryWaypointRow] = []
    for (index, row) in (input["waypoints"] == nil ? [] : try input.array(at: "waypoints"))
      .enumerated()
    {
      let key = try row.string(at: "key")
      let at = try row.number(at: "at")
      waypoints.append(
        ItineraryWaypointRow(
          key: key, place: ProfilePlace(.atDistance(id: key, distance: at)), index: index,
          from: 0, to: at, metrics: ItineraryWaypointRowMetrics(distance: at)))
    }
    let steps = try input.array(at: "steps")
    let rows = (segments: segments, waypoints: waypoints)
    return try await MainActor.run { () throws -> RunnerOutcome in
      let map = MapEngine(client: try MapFixtures.client(), geolocation: InertGeolocation())
      var segmentTable = TableLink(markerId: segmentTableCursorMarkerId)
      var waypointTable = TableLink(markerId: waypointTableCursorMarkerId)
      var hovered: String?
      var highlighted: String?
      var answers: [OrderedJSON] = []
      for step in steps {
        switch try step.string(at: "step") {
        case "point", "leave":
          let pointed = try step.optionalString(at: "row")
          switch try step.string(at: "table") {
          case "segments":
            let row = try pointed.map { id throws(FixtureError) in
              guard let row = rows.segments.first(where: { $0.id == id }) else {
                throw FixtureError(description: "no segment row is `\(id)`")
              }
              return row
            }
            segmentTable.point(at: row?.key, target: segmentRowTarget(row, series: series), on: map)
          case "waypoints":
            let row = try pointed.map { key throws(FixtureError) in
              guard let row = rows.waypoints.first(where: { $0.key == key }) else {
                throw FixtureError(description: "no waypoint row is `\(key)`")
              }
              return row
            }
            waypointTable.point(
              at: row?.key, target: waypointRowTarget(row, series: series), on: map)
          case let other:
            throw FixtureError(description: "no table is `\(other)`")
          }
        case "hover":
          let features = try step.optionalString(at: "segment").map { segment in
            [
              QueriedFeature(
                properties: ["segment_id": .string(segment)],
                geometry: .point(GeoJSONPoint(coordinates: [0, 0])), layer: "itinerary-line")
            ]
          }
          hovered = hoveredLeg(features ?? [])
        case "highlight":
          highlighted = try step.string(at: "row")
        case let other:
          throw FixtureError(description: "no step is called `\(other)`")
        }
        answers.append(
          .object([
            OrderedJSON.Member(
              key: "emphasis",
              value: map.geometry(in: .emphasis).geometry.map(GeoFixtures.written)?["coordinates"]
                ?? .null),
            OrderedJSON.Member(
              key: "lit",
              value: .object([
                OrderedJSON.Member(
                  key: "segments",
                  value: GeoFixtures.texts(
                    rows.segments.filter {
                      isSegmentRowLit(
                        $0, pointed: segmentTable.pointed, highlighted: highlighted,
                        hovered: hovered)
                    }.map(\.id))),
                OrderedJSON.Member(
                  key: "waypoints",
                  value: GeoFixtures.texts(
                    rows.waypoints.filter { $0.key == waypointTable.pointed }.map(\.key))),
              ])),
            OrderedJSON.Member(
              key: "markers",
              value: .array(
                map.state.markers.map { marker in
                  .object([
                    OrderedJSON.Member(key: "id", value: .string(marker.id)),
                    OrderedJSON.Member(key: "lngLat", value: GeoFixtures.numbers(marker.position)),
                  ])
                })),
          ]))
      }
      return .value(.array(answers))
    }
  }
}

/// TableLink is what one table writes to its map, as `MapView`'s tables' link writes it: one cursor
/// marker under the table's own id, moved as the reader points (`map.profile.cursor-marker`), and
/// the leg pointed at lit on the emphasis slot (`map.profile.emphasis`), each taken down where the
/// target states none. Pointing where it already points writes nothing.
@MainActor
private struct TableLink {
  let markerId: String
  private(set) var pointed: String?
  private var pinned: CursorMarkerPin?
  private var isLit = false

  init(markerId: String) {
    self.markerId = markerId
  }

  /// point points the table at the row `key` names, nil for none, and writes `target`.
  mutating func point(at key: String?, target: MapTarget, on map: MapEngine) {
    guard pointed != key else { return }
    pointed = key
    if let lngLat = target.lngLat {
      pinned =
        (try? showCursorMarker(
          on: map, pinned: pinned, point: CursorMarkerPoint(id: markerId, lngLat: lngLat)))
        ?? pinned
    } else {
      hideCursorMarker(on: map, pinned: pinned, id: markerId)
      pinned = nil
    }
    isLit = writeLegEmphasis(on: map, isLit: isLit, stretch: target.stretch, color: nil)
  }
}
