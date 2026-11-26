import MountayaClient
import MountayaGeo
import Testing

@testable import MountayaElements

@Suite("analysisLayers")
struct AnalysisLayersTests {
  private static let stamped: JSONValue = ["get", "mtyaColor"]

  @Test("directions draw a cased line in their own colour, in the itinerary's band")
  func directions() throws {
    let layers = analysisLayers(.directions, sourceId: "route", paint: .standard)

    #expect(layers.map(\.id) == ["route-casing", "route-line"])
    #expect(layers.allSatisfy { $0.source == "route" && $0.rank == LayerRank.itineraryLine.rank })
    #expect(layers.allSatisfy { $0.type == .line })
    let line = try #require(layers.last)
    #expect(line.paint["line-color"] == "#1c7ed6")
    #expect(line.layout == ["line-cap": "round", "line-join": "round"])
    #expect(layers.first?.paint["line-color"] == .string(MapPaint.standard.itinerary.casingColor))
  }

  @Test("suggestions draw the alternatives dashed under the chosen, each in its stamped colour")
  func suggestions() throws {
    let layers = analysisLayers(.suggestions, sourceId: "suggested", paint: .standard)

    #expect(layers.map(\.id) == ["suggested-alternative", "suggested-chosen"])
    #expect(layers.map(\.filter) == [["!", ["get", "chosen"]], ["get", "chosen"]])
    #expect(layers.allSatisfy { $0.paint["line-color"] == Self.stamped })
    #expect(layers.first?.paint["line-dasharray"] == [2, 2])
    #expect(layers.last?.paint["line-dasharray"] == nil)
    #expect(layers.allSatisfy { $0.rank == 50 })
  }

  @Test("isochrones draw a fill in the band's colour and an outline, in the zones' band")
  func isochrones() {
    let layers = analysisLayers(.isochrones, sourceId: "reach", paint: .standard)

    #expect(layers.map(\.id) == ["reach-fill", "reach-outline"])
    #expect(layers.map(\.type) == [.fill, .line])
    #expect(layers.first?.paint == ["fill-color": Self.stamped, "fill-opacity": 0.35])
    #expect(layers.last?.paint == ["line-color": "#0b7285", "line-width": 1])
    #expect(layers.allSatisfy { $0.rank == LayerRank.zone.rank })
  }

  @Test("a matrix draws its connectors as wide as each is stamped, then its locations")
  func matrix() throws {
    let layers = analysisLayers(.matrix, sourceId: "grid", paint: .standard)

    #expect(layers.map(\.id) == ["grid-connector", "grid-location"])
    #expect(layers.map(\.type) == [.line, .circle])
    let connector = try #require(layers.first)
    #expect(connector.paint["line-width"] == ["get", "mtyaWidth"])
    #expect(connector.paint["line-opacity"] == 0.55)
    #expect(connector.filter == ["==", ["get", "mtyaKind"], "matrix-connector"])
    #expect(layers.last?.filter == ["==", ["get", "mtyaKind"], "matrix-location"])
    #expect(layers.last?.paint["circle-color"] == "#7048e8")
    #expect(layers.allSatisfy { $0.rank == 40 })
  }

  @Test("places and points of interest draw a ringed point in the points of interest's band")
  func points() {
    for kind in [AnalysisKind.places, .pois] {
      let layers = analysisLayers(kind, sourceId: "found", paint: .standard)

      #expect(layers.map(\.id) == ["found-point"])
      #expect(
        layers.first?.paint == [
          "circle-color": Self.stamped, "circle-radius": 6, "circle-stroke-color": "#ffffff",
          "circle-stroke-width": 2,
        ])
      #expect(layers.first?.rank == LayerRank.poi.rank)
    }
  }

  @Test("the lines take the map's paint: its dashes, its widths and its casing")
  func paint() throws {
    var paint = MapPaint.standard
    paint.itinerary.dashArray = [1, 3]
    paint.itinerary.lineWidthStops = [7, 3, 16, 6]
    paint.itinerary.casingColor = "#1b1b1b"
    paint.itinerary.casingOpacity = 1

    let suggestions = analysisLayers(.suggestions, sourceId: "s", paint: paint)
    #expect(suggestions.first?.paint["line-dasharray"] == [1, 3])
    #expect(
      suggestions.last?.paint["line-width"] == ["interpolate", ["linear"], ["zoom"], 7, 3, 16, 6])
    let casing = try #require(analysisLayers(.directions, sourceId: "d", paint: paint).first)
    #expect(casing.paint["line-color"] == "#1b1b1b")
    #expect(casing.paint["line-opacity"] == 1)
  }
}
