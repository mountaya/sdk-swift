import MountayaClient
import MountayaGeo
import Testing

@testable import MountayaElements

@Suite("roadAccessLayersOf")
struct RoadAccessLayersOfTests {
  private static func layer(
    _ id: String, sourceLayer: String, type: TileSchema.TileLayerType = .line,
    width: JSONValue? = nil, zoom: (Int, Int) = (0, 22), source: String? = nil
  ) -> TileSchema.TileLayer {
    TileSchema.TileLayer(
      id: id, key: id, layout: nil, paint: width.map { ["line-width": $0] },
      source_layer: sourceLayer, type: type, zoom_max: zoom.1, zoom_min: zoom.0
    ) { $0.source = source }
  }

  private static func source(_ layers: [TileSchema.TileLayer]) -> TileSchema.TileSource {
    TileSchema.TileSource(
      id: "itinerary", layers: layers, tiles: ["https://tiles.test/itinerary/{z}/{x}/{y}"],
      type: .vector, zoom_max: 22, zoom_min: 0)
  }

  @Test("one pair stands beside the first itinerary line that is no casing, at its rank and width")
  func pair() throws {
    let layers = roadAccessLayersOf(
      Self.source([
        Self.layer("line-a-casing", sourceLayer: "itinerary_lines", width: 6),
        Self.layer("line-a", sourceLayer: "itinerary_lines", width: 4, zoom: (6, 22)),
        Self.layer("line-a-dashed", sourceLayer: "itinerary_lines", width: 4),
        Self.layer("point-a", sourceLayer: "itinerary_points", type: .symbol, zoom: (11, 22)),
      ]))

    #expect(layers.map(\.id) == ["line-a__road-access-stripe", "line-a__road-access-icon"])
    #expect(layers.map(\.rank) == [55, 90])
    #expect(layers.allSatisfy { $0.sourceLayer == "itinerary_restrictions" })
    #expect(layers.allSatisfy { $0.source == "itinerary" && $0.key == nil })
    let stripes = try #require(layers.first)
    #expect(stripes.type == .line)
    #expect(stripes.paint["line-width"] == 4)
    #expect(stripes.paint["line-opacity"] == 0.9)
    #expect(stripes.layout == ["line-cap": "round", "line-join": "round"])
    #expect(stripes.zoom == ZoomBounds(minZoom: 6, maxZoom: 22))
    let icons = try #require(layers.last)
    #expect(icons.type == .symbol)
    #expect(icons.zoom == ZoomBounds(minZoom: 11, maxZoom: 22), "the waypoints' window")
    #expect(icons.layout["icon-size"] == 0.7)
    #expect(icons.layout["symbol-placement"] == "line-center")
    #expect(icons.paint == ["icon-opacity": 1])
  }

  @Test("each image is matched on the kind, most severe first, an unnamed kind drawn as restricted")
  func images() throws {
    let layers = roadAccessLayersOf(
      Self.source([Self.layer("route", sourceLayer: "itinerary_lines")]))
    let stripes = try #require(layers.first?.paint["line-pattern"])
    let icons = try #require(layers.last?.layout["icon-image"])

    #expect(
      stripes == [
        "match", ["get", "kind"], "forbidden", "road-access-stripe-forbidden", "private",
        "road-access-stripe-private", "permit", "road-access-stripe-permit", "service",
        "road-access-stripe-service", "local-access", "road-access-stripe-local-access",
        "restricted", "road-access-stripe-restricted", "road-access-stripe-restricted",
      ])
    #expect(
      icons == [
        "match", ["get", "kind"], "forbidden", "section-icon-road-access-forbidden-e03131",
        "private", "section-icon-road-access-private-e8590c", "permit",
        "section-icon-road-access-permit-9c36b5", "service",
        "section-icon-road-access-service-1971c2",
        "local-access", "section-icon-road-access-local-access-0c8599", "restricted",
        "section-icon-road-access-restricted-495057", "section-icon-road-access-restricted-495057",
      ])
    #expect(roadAccessIconImageId(.permit) == "section-icon-road-access-permit-9c36b5")
  }

  @Test(
    "a line stating no width has stripes 1 wide, and the icons take its window with no waypoints")
  func unstated() throws {
    let layers = roadAccessLayersOf(
      Self.source([Self.layer("route", sourceLayer: "itinerary_lines", zoom: (5, 18))]))
    #expect(layers.first?.paint["line-width"] == 1)
    #expect(layers.last?.zoom == ZoomBounds(minZoom: 5, maxZoom: 18))
    let expression: JSONValue = ["interpolate", ["linear"], ["zoom"], 7, 2, 16, 5]
    let interpolated = roadAccessLayersOf(
      Self.source([Self.layer("route", sourceLayer: "itinerary_lines", width: expression)]))
    #expect(interpolated.first?.paint["line-width"] == expression)
  }

  @Test("a line naming its own source binds the stretches to it")
  func ownSource() {
    let layers = roadAccessLayersOf(
      Self.source([Self.layer("route", sourceLayer: "itinerary_lines", source: "itinerary-live")]))
    #expect(layers.map(\.source) == ["itinerary-live", "itinerary-live"])
  }

  @Test("stretches the host hid are born hidden")
  func hidden() {
    let layers = roadAccessLayersOf(
      Self.source([Self.layer("route", sourceLayer: "itinerary_lines")]), isShown: false)
    #expect(layers.allSatisfy { $0.isHidden })
  }

  @Test("a source of no itinerary line, a label or a casing alone draws no stretch")
  func none() {
    #expect(
      roadAccessLayersOf(
        Self.source([
          Self.layer("zone-fill", sourceLayer: "fills", type: .fill),
          Self.layer("o", sourceLayer: "fills"),
        ])
      )
      .isEmpty)
    #expect(
      roadAccessLayersOf(
        Self.source([
          Self.layer("slope-line", sourceLayer: "slope"),
          Self.layer("route-label", sourceLayer: "itinerary_lines", type: .symbol),
          Self.layer("route-casing", sourceLayer: "itinerary_lines"),
        ])
      ).isEmpty)
    #expect(
      roadAccessLayersOf(
        Self.source([Self.layer("route-casing\u{301}", sourceLayer: "itinerary_lines")])
      ).count
        == 2, "a casing is told by its id's scalars")
  }
}
