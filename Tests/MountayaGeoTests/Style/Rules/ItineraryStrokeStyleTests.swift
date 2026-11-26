import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("itineraryStrokeStyle")
struct ItineraryStrokeStyleTests {
  private let round: [String: JSONValue] = ["line-cap": "round", "line-join": "round"]
  private let lineWidth: JSONValue = [
    "interpolate", ["linear"], ["zoom"], 7, 2, 10, 2, 13, 3, 16, 5,
  ]
  private let casingWidth: JSONValue = [
    "interpolate", ["linear"], ["zoom"], 7, 4, 10, 4, 13, 5, 16, 7,
  ]

  @Test("a line strokes round in its colour at the line's widths")
  func line() {
    #expect(
      itineraryStrokeStyle(.line(color: "#123456"))
        == LineLayerStyle(layout: round, paint: ["line-color": "#123456", "line-width": lineWidth]))
  }

  @Test("a casing strokes round in the casing's colour and opacity, wider at every stop")
  func casing() {
    #expect(
      itineraryStrokeStyle(.casing)
        == LineLayerStyle(
          layout: round,
          paint: ["line-color": "#ffffff", "line-opacity": 0.9, "line-width": casingWidth]))
  }

  @Test("a provisional stroke is the line, dashed at reduced opacity")
  func dashed() {
    let dashed = itineraryStrokeStyle(.dashed(color: "#868e96"))
    #expect(
      dashed
        == LineLayerStyle(
          layout: round,
          paint: [
            "line-color": "#868e96", "line-dasharray": [2, 2], "line-opacity": 0.6,
            "line-width": lineWidth,
          ]))
    let solid = itineraryStrokeStyle(.line(color: "#868e96"))
    #expect(sameJson(dashed.layout, solid.layout))
    #expect(dashed.paint["line-width"].map { sameJson($0, lineWidth) } == true)
  }

  @Test("a colour read from the feature is written as the expression")
  func expression() {
    let style = itineraryStrokeStyle(.line(color: ["get", "mtyaColor"]))
    #expect(style.paint["line-color"].map { sameJson($0, ["get", "mtyaColor"]) } == true)
  }

  @Test("the paint handed is the one stroked")
  func patched() {
    var paint = MapPaint.standard
    paint.itinerary.dashArray = [1, 3]
    paint.itinerary.lineWidthStops = [7, 3, 16, 6]
    #expect(
      itineraryStrokeStyle(.dashed(color: "#2b8a3e"), paint: paint)
        == LineLayerStyle(
          layout: round,
          paint: [
            "line-color": "#2b8a3e", "line-dasharray": [1, 3], "line-opacity": 0.6,
            "line-width": ["interpolate", ["linear"], ["zoom"], 7, 3, 16, 6],
          ]))

    var casing = MapPaint.standard
    casing.itinerary.casingColor = "#1b1b1b"
    casing.itinerary.casingOpacity = 1
    #expect(
      itineraryStrokeStyle(.casing, paint: casing)
        == LineLayerStyle(
          layout: round,
          paint: ["line-color": "#1b1b1b", "line-opacity": 1, "line-width": casingWidth]))
    // A line states no opacity of its own, and reads no member of the casing's.
    #expect(
      itineraryStrokeStyle(.line(color: "#2b8a3e"), paint: casing)
        == itineraryStrokeStyle(.line(color: "#2b8a3e")))
  }

  /// A table and a dash are the paint's as it holds them: one of no stop or of an odd count is
  /// written as it stands, and MapLibre refuses the layer it would draw.
  @Test("a table and a dash are written as the paint holds them")
  func asHeld() {
    var paint = MapPaint.standard
    paint.itinerary.lineWidthStops = []
    paint.itinerary.casingWidthStops = [7]
    paint.itinerary.dashArray = []
    #expect(
      itineraryStrokeStyle(.dashed(color: "#000000"), paint: paint).paint["line-width"]
        .map { sameJson($0, ["interpolate", ["linear"], ["zoom"]]) } == true)
    #expect(
      itineraryStrokeStyle(.casing, paint: paint).paint["line-width"]
        .map { sameJson($0, ["interpolate", ["linear"], ["zoom"], 7]) } == true)
    #expect(
      itineraryStrokeStyle(.dashed(color: "#000000"), paint: paint).paint["line-dasharray"]
        .map { sameJson($0, []) } == true)
  }
}
