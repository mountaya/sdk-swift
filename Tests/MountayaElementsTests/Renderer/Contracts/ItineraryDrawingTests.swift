import MountayaClient
import MountayaGeo
import RendererSupport
import Testing

@testable import MountayaElements

@Suite("ItineraryDrawing")
@MainActor
struct ItineraryDrawingTests {
  private static let drawing = ItineraryDrawing(resolved: Itineraries.resolved, legs: nil)

  @Test("the itinerary's legs are its curve and its rows, its places its pins and its rows")
  func whole() {
    let drawing = Self.drawing
    let points = drawing.series.points
    let total = drawing.series.totalDistance

    #expect(points.map(\.elevation) == [1_000, 1_200, 1_400, 1_400, 1_250, 1_100])
    #expect(points[2].distance == points[3].distance, "the seam between two legs is free")
    #expect(drawing.rows.map(\.id) == ["climb", "descent"])
    #expect(drawing.rows.map(\.name) == ["Climb", "Descent"])
    #expect(drawing.rows[0].from == 0 && drawing.rows[1].to == total)
    #expect(drawing.rows[0].to == drawing.rows[1].from)
    #expect(abs(drawing.rows[0].to - total / 2) < 1e-6)
    #expect(drawing.places.map(\.id) == ["hut", "col", "spring"])
    #expect(drawing.waypointRows.map(\.place.id) == ["hut", "col", "spring"])
    #expect(drawing.whole == ProfileRange(from: 0, to: total))
    #expect(drawing.characteristics.ascent == 400, "read off the curve, the server stating none")
    #expect(drawing.characteristics.descent == 300)
  }

  @Test("a chain the app states is the curve, its legs the rows, the places still the itinerary's")
  func chain() throws {
    let climb = try #require(Itineraries.resolved.legs.first)
    let drawing = ItineraryDrawing(resolved: Itineraries.resolved, legs: [climb])

    #expect(drawing.series.points.map(\.elevation) == [1_000, 1_200, 1_400])
    #expect(drawing.rows.map(\.id) == ["climb"])
    #expect(drawing.places.map(\.id) == ["hut", "col", "spring"])
  }

  @Test("an itinerary not answered yet draws nothing, and points nowhere")
  func nothing() {
    let drawing = ItineraryDrawing(resolved: nil, legs: nil)

    #expect(drawing.series.points.isEmpty)
    #expect(drawing.rows.isEmpty && drawing.places.isEmpty && drawing.waypointRows.isEmpty)
    #expect(drawing.cursorTarget(at: 0) == MapTarget())
  }

  @Test(
    "a cursor pins the marker at its sample and lights its leg, the later one at a shared meter")
  func cursor() {
    let drawing = Self.drawing
    let points = drawing.series.points
    let climb = lineBetween(points, from: drawing.rows[0].from, to: drawing.rows[0].to)
    let descent = lineBetween(points, from: drawing.rows[1].from, to: drawing.rows[1].to)

    #expect(drawing.cursorTarget(at: 1) == MapTarget(lngLat: points[1].lngLat, stretch: climb))
    #expect(drawing.cursorTarget(at: 2) == MapTarget(lngLat: points[2].lngLat, stretch: descent))
    #expect(drawing.cursorTarget(at: 5) == MapTarget(lngLat: points[5].lngLat, stretch: descent))
    #expect(drawing.cursorTarget(at: nil) == MapTarget())
    #expect(drawing.cursorTarget(at: 6) == MapTarget(), "no sample stands there")
  }

  @Test("a leg's row pins the marker at its end and lights itself; a place's row pins at the place")
  func rows() throws {
    let drawing = Self.drawing
    let points = drawing.series.points
    let climb = drawing.rows[0]
    let hut = try #require(drawing.waypointRows.first)

    #expect(
      drawing.segmentTarget(climb)
        == MapTarget(
          lngLat: [6, 45.01], stretch: lineBetween(points, from: climb.from, to: climb.to)))
    #expect(drawing.segmentTarget(nil) == MapTarget())
    #expect(drawing.waypointTarget(hut) == MapTarget(lngLat: [6, 45.005]))
    #expect(drawing.waypointTarget(nil) == MapTarget())
  }
}
