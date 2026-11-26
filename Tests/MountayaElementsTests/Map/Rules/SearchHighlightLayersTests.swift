import MountayaClient
import MountayaGeo
import Testing

@testable import MountayaElements

@Suite("searchHighlightLayers")
struct SearchHighlightLayersTests {
  private static let accent = HexColor(hex: "#1c7ed6")

  private static func ids(_ layers: [MapLayer]) -> [String] {
    layers.map(\.id)
  }

  @Test("a place is the pin carrying a point in the accent, or the map pin where none is held")
  func place() {
    let drawn = searchHighlightLayers(
      .place(point: [6.86, 45.83]), accent: Self.accent, hasPointGlyph: true)

    #expect(Self.ids(drawn.layers) == ["mountaya-search-highlight-place"])
    let pin = drawn.layers[0]
    #expect(pin.type == .symbol)
    #expect(pin.rank == LayerRank.chrome.rank)
    #expect(pin.source == searchHighlightSourceId)
    #expect(pin.paint.isEmpty)
    #expect(
      pin.layout == [
        "icon-allow-overlap": true, "icon-ignore-placement": true,
        "icon-image": "poi-icon-point-1c7ed6", "icon-size": 0.7,
      ])
    #expect(
      drawn.features
        == GeoJSONFeatureCollection(features: [
          GeoJSONFeature(
            geometry: .point(GeoJSONPoint(coordinates: [6.86, 45.83])), properties: [:])
        ]))
    let fallback = searchHighlightLayers(
      .place(point: [6.86, 45.83]), accent: HexColor(hex: "#E8590C"), hasPointGlyph: false)
    #expect(fallback.layers[0].layout["icon-image"] == "poi-icon-map-pin-e8590c")
  }

  @Test("a point of interest is its category's own pin in its colour, else a place's pin")
  func poi() {
    let drawn = searchHighlightLayers(
      .poi(point: [6.8652, 45.8326], category: .peak), accent: Self.accent, hasPointGlyph: true)

    #expect(Self.ids(drawn.layers) == ["mountaya-search-highlight-poi"])
    #expect(drawn.layers[0].layout["icon-image"] == "poi-icon-mountain-5d4037")
    #expect(drawn.features.features.first?.properties == ["category": "PEAK"])
    for category in [nil, DataSchema.POICategory(rawValue: "GLACIER")] {
      let unstyled = searchHighlightLayers(
        .poi(point: [6.8652, 45.8326], category: category), accent: Self.accent,
        hasPointGlyph: true)
      #expect(Self.ids(unstyled.layers) == ["mountaya-search-highlight-place"])
      #expect(unstyled.layers[0].layout["icon-image"] == "poi-icon-point-1c7ed6")
      #expect(unstyled.features.features.first?.properties == [:])
    }
  }

  @Test("a way with a line is that line, haloed and cased, with a dot at each of its two ends")
  func line() throws {
    let coordinates = [[6.8, 45.8], [6.85, 45.82], [6.9, 45.85]]
    let drawn = searchHighlightLayers(
      .way(anchor: [6.85, 45.82], bounds: [6.8, 45.8, 6.9, 45.85], coordinates: coordinates),
      accent: HexColor(hex: "#e8590c"), hasPointGlyph: true)

    #expect(
      Self.ids(drawn.layers) == [
        "mountaya-search-highlight-halo", "mountaya-search-highlight-casing",
        "mountaya-search-highlight-line", "mountaya-search-highlight-endpoints",
      ])
    #expect(drawn.layers.allSatisfy { $0.rank == 100 })
    let rounded: [String: JSONValue] = ["line-cap": "round", "line-join": "round"]
    #expect(
      drawn.layers[0].paint
        == ["line-blur": 6, "line-color": "#e8590c", "line-opacity": 0.25, "line-width": 16])
    #expect(drawn.layers[0].layout == rounded)
    #expect(drawn.layers[1].paint == ["line-color": "#ffffff", "line-width": 8])
    #expect(drawn.layers[2].paint == ["line-color": "#e8590c", "line-width": 5])
    let ends = drawn.layers[3]
    #expect(ends.type == .circle)
    #expect(ends.filter == ["==", ["geometry-type"], "Point"], "the ends read the points alone")
    #expect(
      ends.paint == [
        "circle-color": "#e8590c", "circle-radius": 5, "circle-stroke-color": "#ffffff",
        "circle-stroke-width": 2,
      ])
    #expect(
      drawn.features.features.map(\.geometry) == [
        .lineString(GeoJSONLineString(coordinates: coordinates)),
        .point(GeoJSONPoint(coordinates: [6.8, 45.8])),
        .point(GeoJSONPoint(coordinates: [6.9, 45.85])),
      ])
  }

  @Test("a way of no line is its extent washed and outlined dashed, across the antimeridian")
  func extent() {
    let drawn = searchHighlightLayers(
      .way(anchor: [6.5, 45.5], bounds: [6, 45, 7, 46], coordinates: [[6.5, 45.5]]),
      accent: Self.accent, hasPointGlyph: true)

    #expect(
      Self.ids(drawn.layers) == [
        "mountaya-search-highlight-bounds-fill", "mountaya-search-highlight-bounds",
      ], "a line of one position is no line")
    #expect(drawn.layers[0].paint == ["fill-color": "#1c7ed6", "fill-opacity": 0.08])
    #expect(
      drawn.layers[1].paint
        == ["line-color": "#1c7ed6", "line-dasharray": [2, 2], "line-width": 2])
    #expect(
      drawn.features.features.first?.geometry
        == .polygon(
          GeoJSONPolygon(coordinates: [[[6, 45], [7, 45], [7, 46], [6, 46], [6, 45]]])))
    let across = searchHighlightLayers(
      .way(anchor: [179.9, -16.5], bounds: [179.5, -17, -179.5, -16], coordinates: nil),
      accent: Self.accent, hasPointGlyph: true)
    #expect(
      across.features.features.first?.geometry
        == .polygon(
          GeoJSONPolygon(coordinates: [
            [[179.5, -17], [180.5, -17], [180.5, -16], [179.5, -16], [179.5, -17]]
          ])))
  }

  @Test("an extent of no area, or of an edge at no number, gives way to a pin at the anchor")
  func degenerate() {
    for bounds in [
      [6, 45, 6, 46], [6, 46, 7, 45], [.nan, 45, 7, 46], [180, 45, -180, 46], [6, 45, 7],
      [6, 45, .infinity, 46],
    ] {
      let drawn = searchHighlightLayers(
        .way(anchor: [6.5, 45.5], bounds: bounds, coordinates: nil), accent: Self.accent,
        hasPointGlyph: true)
      #expect(Self.ids(drawn.layers) == ["mountaya-search-highlight-place"], "\(bounds)")
      #expect(
        drawn.features.features.first?.geometry == .point(GeoJSONPoint(coordinates: [6.5, 45.5])))
    }
    let bare = searchHighlightLayers(
      .way(anchor: [6.5, 45.5], bounds: nil, coordinates: nil), accent: Self.accent,
      hasPointGlyph: false)
    #expect(bare.layers[0].layout["icon-image"] == "poi-icon-map-pin-1c7ed6")
  }
}
