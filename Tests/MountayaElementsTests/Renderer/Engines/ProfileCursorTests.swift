import MountayaGeo
import Observation
import RendererSupport
import Testing
import os

@testable import MountayaElements

@Suite("ProfileCursor")
@MainActor
struct ProfileCursorTests {
  private static let drawing = ItineraryDrawing(resolved: Itineraries.resolved, legs: nil)

  /// point stands `cursor` on sample `index` of the test itinerary, as a profile's scrub does.
  private static func point(
    _ cursor: ProfileCursor, at index: Int?, isEnabled: Bool = true, map: MapEngine? = nil
  ) {
    let sample = index.map { drawing.series.points[$0] }
    cursor.point(
      at: index, value: sample, target: drawing.cursorTarget(at: index), isEnabled: isEnabled,
      onHover: nil, map: map, markerColor: nil, emphasisColor: nil)
  }

  @Test("a cursor stands on the sample a scrub points at, and writes it to the map")
  func stands() throws {
    let cursor = ProfileCursor(markerId: profileCursorMarkerId)
    let map = try Maps.engine()

    #expect(cursor.index == nil)
    #expect(cursor.sample(in: Self.drawing.series) == nil)
    Self.point(cursor, at: 4, map: map)
    #expect(cursor.index == 4)
    #expect(cursor.sample(in: Self.drawing.series) == Self.drawing.series.points[4])
    #expect(
      map.state.markers.first { $0.id == profileCursorMarkerId }?.position
        == Self.drawing.series.points[4].lngLat)

    // A disabled profile points at nothing new, and only lets go.
    Self.point(cursor, at: 1, isEnabled: false, map: map)
    #expect(cursor.index == 4)
    Self.point(cursor, at: nil, isEnabled: false, map: map)
    #expect(cursor.index == nil)
    #expect(map.state.markers.isEmpty)
  }

  /// A view reading the cursor is drawn again only where it moves, so a pointer moving within one
  /// column of the chart redraws nothing.
  @Test("a reader of the cursor is told where it moves, and never where it stood already")
  func toldWhereItMoves() {
    let cursor = ProfileCursor(markerId: profileCursorMarkerId)
    let told = OSAllocatedUnfairLock(initialState: 0)
    func follow() {
      withObservationTracking {
        _ = cursor.index
      } onChange: {
        told.withLock { $0 += 1 }
      }
    }

    follow()
    Self.point(cursor, at: 2)
    #expect(told.withLock { $0 } == 1)
    follow()
    Self.point(cursor, at: 2)
    Self.point(cursor, at: 2)
    #expect(told.withLock { $0 } == 1, "standing where it stood tells nothing")
    Self.point(cursor, at: 5)
    #expect(told.withLock { $0 } == 2)
  }

  @Test("a sample outside the series is no sample to stand on")
  func outside() {
    let cursor = ProfileCursor(markerId: profileCursorMarkerId)
    cursor.point(
      at: 40, value: nil, target: MapTarget(), isEnabled: true, onHover: nil, map: nil,
      markerColor: nil, emphasisColor: nil)

    #expect(cursor.index == 40)
    #expect(cursor.sample(in: Self.drawing.series) == nil)
  }
}
