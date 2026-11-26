import MountayaClient
import MountayaElements
import MountayaGeo
import Testing

@Suite("MapLayer")
struct MapLayerTests {
  private static func tileLayer(
    _ sourceLayer: String, type: TileSchema.TileLayerType = .line
  )
    -> TileSchema.TileLayer
  {
    TileSchema.TileLayer(
      id: "itineraries-\(sourceLayer)", key: sourceLayer,
      layout: ["line-cap": "round"], paint: ["line-color": ["get", "color"]],
      source_layer: sourceLayer, type: type, zoom_max: 22, zoom_min: 4
    ) { $0.filter = ["==", ["geometry-type"], "LineString"] }
  }

  @Test("a tile specification's layer takes the rank its source layer declares, and its members")
  func fromSpecification() {
    let layer = MapLayer(Self.tileLayer("itinerary_lines"), source: "itineraries")

    #expect(layer.id == "itineraries-itinerary_lines")
    #expect(layer.rank == LayerRank.itineraryLine.rank)
    #expect(layer.source == "itineraries")
    #expect(layer.sourceLayer == "itinerary_lines")
    #expect(layer.paint == ["line-color": ["get", "color"]])
    #expect(layer.layout == ["line-cap": "round"])
    #expect(layer.filter == ["==", ["geometry-type"], "LineString"])
    #expect(layer.zoom == ZoomBounds(minZoom: 4, maxZoom: 22))
    #expect(layer.key == "itinerary_lines")
  }

  @Test(
    "a raster or a hillshade carries no source layer and no filter, an empty source layer and key none"
  )
  func readsRaster() {
    for type in [TileSchema.TileLayerType.raster, .hillshade] {
      let layer = MapLayer(Self.tileLayer("imagery", type: type), source: "s")
      #expect(layer.sourceLayer == nil)
      #expect(layer.filter == nil)
    }
    let empty = TileSchema.TileLayer(
      id: "zone-fill", key: "", layout: nil, paint: nil, source_layer: "",
      type: .fill, zoom_max: 22, zoom_min: 0)
    let unnamed = MapLayer(empty, source: "zones")
    #expect(unnamed.sourceLayer == nil)
    #expect(unnamed.key == nil)
    #expect(unnamed.paint.isEmpty && unnamed.layout.isEmpty)
    let own = TileSchema.TileLayer(
      id: "rain", key: "rain", layout: nil, paint: nil, source_layer: "precipitation",
      type: .fill, zoom_max: 22, zoom_min: 0
    ) { $0.source = "weather-live" }
    #expect(MapLayer(own, source: "weather").source == "weather-live")
  }

  @Test("a layer is hidden where its layout writes its visibility none, and only there")
  func hidden() {
    var layer = MapLayer(id: "a", type: .line, source: "s", rank: 50)
    #expect(!layer.isHidden)
    layer.layout["visibility"] = "none"
    #expect(layer.isHidden)
    layer.layout["visibility"] = "visible"
    #expect(!layer.isHidden)
    layer.layout["visibility"] = 0
    #expect(!layer.isHidden)
  }

  @Test(
    "a hillshade is the terrain's rank, an unknown source layer an overlay's, a patched table its own"
  )
  func ranks() {
    #expect(
      MapLayer(Self.tileLayer("itinerary_lines", type: .hillshade), source: "s").rank
        == LayerRank.hillshade.rank)
    #expect(MapLayer(Self.tileLayer("snow_depth"), source: "s").rank == LayerRank.overlay.rank)
    var ranks = tileSourceLayerRanks
    ranks["snow_depth"] = LayerRank.poi.rank + 2
    #expect(MapLayer(Self.tileLayer("snow_depth"), source: "s", ranks: ranks).rank == 82)
  }

  @Test("two layers are equal where they state the same, a NaN the same as a NaN")
  func equality() {
    let layer = MapLayer(
      id: "route", type: .line, source: "route", rank: 50,
      paint: ["line-width": .number(.nan)])

    #expect(layer == layer)
    var other = layer
    other.paint["line-width"] = 4
    #expect(layer != other)
    var filtered = layer
    filtered.filter = .null
    #expect(layer != filtered)
  }

  @Test("an id is compared by its scalars, so two spellings of one text are two layers")
  func scalars() {
    let composed = MapLayer(id: "caf\u{E9}", type: .line, source: "s", rank: 50)
    let decomposed = MapLayer(id: "cafe\u{301}", type: .line, source: "s", rank: 50)

    #expect(composed != decomposed)
  }
}
