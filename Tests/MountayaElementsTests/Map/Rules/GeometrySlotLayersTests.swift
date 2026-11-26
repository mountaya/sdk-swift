import MountayaClient
import MountayaGeo
import Testing

@testable import MountayaElements

@Suite("geometrySlotLayers")
struct GeometrySlotLayersTests {
  @Test("the highlight draws a cased line and a point, at the chrome band")
  func highlight() throws {
    let layers = geometrySlotLayers(.highlight, color: "#f59f00", paint: .standard)

    #expect(
      layers.map(\.id) == [
        "mountaya-highlight-casing", "mountaya-highlight-line", "mountaya-highlight-point",
      ])
    #expect(layers.allSatisfy { $0.source == "mountaya-highlight" && $0.rank == 100 })
    let point = try #require(layers.last)
    #expect(point.type == .circle)
    #expect(point.filter == ["in", ["geometry-type"], ["literal", ["Point", "MultiPoint"]]])
    #expect(
      point.paint == [
        "circle-color": "#f59f00", "circle-radius": 6, "circle-stroke-color": "#ffffff",
        "circle-stroke-width": 2,
      ])
    #expect(layers[1].paint["line-color"] == "#f59f00")
  }

  @Test("the preview and the emphasis draw a cased line just above the itinerary, and no point")
  func focus() {
    for slot in [GeometrySlot.preview, .emphasis] {
      let layers = geometrySlotLayers(slot, color: slot.color, paint: .standard)

      #expect(layers.map(\.id) == ["\(slot.sourceId)-casing", "\(slot.sourceId)-line"])
      #expect(layers.allSatisfy { $0.rank == 52 && $0.type == .line })
      #expect(layers.last?.paint["line-color"] == .string(slot.color))
    }
  }

  @Test("the slot's lines take the map's paint, the point's ring its casing colour")
  func paint() throws {
    var paint = MapPaint.standard
    paint.itinerary.casingColor = "#1b1b1b"
    paint.itinerary.lineWidthStops = [7, 3, 16, 6]

    let emphasis = geometrySlotLayers(.emphasis, color: "#7048e8", paint: paint)
    #expect(emphasis.first?.paint["line-color"] == "#1b1b1b")
    #expect(
      emphasis.last?.paint["line-width"] == ["interpolate", ["linear"], ["zoom"], 7, 3, 16, 6])
    #expect(emphasis.last?.paint["line-color"] == "#7048e8")
    let point = try #require(geometrySlotLayers(.highlight, color: "#123456", paint: paint).last)
    #expect(point.paint["circle-stroke-color"] == "#1b1b1b")
  }
}
