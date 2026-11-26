import GateSupport
import MountayaClient
import MountayaElements
import MountayaGeo

extension PublicRunners {
  /// mapSearchResultHighlight answers what a map draws for the case's `payload` in its `accent`,
  /// over a glyph set that draws a point or none as its `hasPointGlyph` says, through the real
  /// engine's `setSearchHighlight(_:accent:)`: the one source the highlight draws from, written as
  /// MapLibre's style specification writes a GeoJSON source, its layers in the order they stack, and
  /// the band they draw at. Every width, opacity, blur, radius, dash, glyph, the band and the
  /// source are read back through what the engine draws for a way's line, a way's extent and a
  /// place, under a set that holds a point and one that holds none.
  static let mapSearchResultHighlight = Runner(
    id: "map.search.result-highlight", table: .public
  ) { fixture, fixtureCase in
    let held = try await MapSearchFixtures.style()
    try fixture.holdConstants(["rank": held.rank], values: held.values)
    let input = fixtureCase.input
    guard let written = input["payload"] else {
      throw FixtureError(description: "the case has no `payload`")
    }
    let highlight = try MapSearchFixtures.highlight(written)
    let accent = HexColor(hex: try input.string(at: "accent"))
    let hasPointGlyph = try input.flag(at: "hasPointGlyph")
    let drawn = try await MapSearchFixtures.drawn(
      highlight, accent: accent, hasPointGlyph: hasPointGlyph)
    return .value(drawn.written)
  }
}

/// MapSearchFixtures draws a picked result on a map engine and writes what it drew as
/// `map/search-result-highlight.json` expects it.
enum MapSearchFixtures {
  /// Drawn is what a map draws for a picked result: its source's id and features, and its layers
  /// in the order they stack.
  struct Drawn: Sendable {
    let sourceId: String
    let source: MapSource
    let layers: [MapLayer]

    /// written is the drawing as the fixture writes it: `sources`, `layers` and `rank`.
    var written: OrderedJSON {
      var data: OrderedJSON = .null
      if case .geoJson(let collection) = source.kind {
        data = MapSearchFixtures.written(collection)
      }
      return .object([
        OrderedJSON.Member(key: "layers", value: .array(layers.map(MapFixtures.styleLayer))),
        OrderedJSON.Member(
          key: "rank", value: layers.first.map { .number(Double($0.rank)) } ?? .null),
        OrderedJSON.Member(
          key: "sources",
          value: .object([
            OrderedJSON.Member(
              key: sourceId,
              value: .object([
                OrderedJSON.Member(key: "data", value: data),
                OrderedJSON.Member(key: "type", value: .string("geojson")),
              ]))
          ])),
      ])
    }
  }

  /// drawn draws `highlight` in `accent` on a map whose glyph set draws a point where
  /// `hasPointGlyph` says so, and answers the one source and the layers it holds for it. A drawing
  /// whose layers stand at more than one band, or which adds more than one source, fails.
  @MainActor
  static func drawn(_ highlight: SearchHighlight, accent: HexColor, hasPointGlyph: Bool) throws
    -> Drawn
  {
    let map = MapEngine(
      client: try MapFixtures.client(), glyphs: try glyphs(hasPointGlyph: hasPointGlyph),
      geolocation: InertGeolocation())
    map.setSearchHighlight(highlight, accent: accent)
    let state = map.state
    guard state.sources.count == 1, let source = state.sources.first else {
      throw FixtureError(description: "the map drew \(state.sources.count) sources")
    }
    let layers = state.layers.filter { $0.source == source.id }
    guard layers.count == state.layers.count, Set(layers.map(\.rank)).count == 1 else {
      throw FixtureError(description: "the map drew layers apart from its source or its band")
    }
    return Drawn(sourceId: source.id, source: source, layers: layers)
  }

  /// glyphs is the bundled marker set, or that set without the point a place's pin carries.
  private static func glyphs(hasPointGlyph: Bool) throws(FixtureError) -> GlyphSet {
    let marker = GlyphSet.marker
    guard !hasPointGlyph else { return marker }
    guard
      let set = GlyphSet(
        name: "markers-without-point", paint: marker.paint, strokeWidth: marker.strokeWidth,
        viewBox: marker.viewBox, markup: marker.markup.filter { $0.key != "point" })
    else { throw FixtureError(description: "the marker set without its point cannot be drawn") }
    return set
  }

  /// HeldStyle is the highlight's constants as a map draws them.
  struct HeldStyle: Sendable {
    let rank: Double
    let values: [String: OrderedJSON]
  }

  /// style reads the highlight's constants back through what a map draws: a way's line, a way's
  /// extent, and a place's pin under a set that holds a point and one that holds none.
  static func style() async throws -> HeldStyle {
    try await MainActor.run { () throws -> HeldStyle in
      let accent = HexColor(hex: "#1c7ed6")
      let line = try drawn(
        .way(anchor: [6.85, 45.82], bounds: nil, coordinates: [[6.8, 45.8], [6.9, 45.85]]),
        accent: accent, hasPointGlyph: true)
      let extent = try drawn(
        .way(anchor: [6.5, 45.5], bounds: [6, 45, 7, 46], coordinates: nil), accent: accent,
        hasPointGlyph: true)
      let place = try drawn(.place(point: [6.86, 45.83]), accent: accent, hasPointGlyph: true)
      let fallback = try drawn(.place(point: [6.86, 45.83]), accent: accent, hasPointGlyph: false)
      func layer(_ drawn: Drawn, role: String) throws(FixtureError) -> MapLayer {
        guard let found = drawn.layers.first(where: { $0.id == "\(drawn.sourceId)-\(role)" }) else {
          throw FixtureError(description: "the map drew no `\(role)` layer")
        }
        return found
      }
      func number(_ layer: MapLayer, named name: String, paint: Bool = true) -> OrderedJSON {
        GeoFixtures.ordered((paint ? layer.paint : layer.layout)[name] ?? .null)
      }
      func glyph(_ drawn: Drawn) throws(FixtureError) -> OrderedJSON {
        let pin = try layer(drawn, role: "place")
        guard case .string(let image)? = pin.layout["icon-image"] else {
          throw FixtureError(description: "a pin names no image")
        }
        // `poi-icon-`, the glyph, a hyphen and six hexadecimal digits.
        return .string(String(image.dropFirst("poi-icon-".count).dropLast(7)))
      }
      let halo = try layer(line, role: "halo")
      let casing = try layer(line, role: "casing")
      let ends = try layer(line, role: "endpoints")
      let pin = try layer(place, role: "place")
      return HeldStyle(
        rank: Double(place.layers.first?.rank ?? -1),
        values: [
          "casing": .object([
            OrderedJSON.Member(key: "color", value: number(casing, named: "line-color")),
            OrderedJSON.Member(key: "width", value: number(casing, named: "line-width")),
          ]),
          "ends": .object([
            OrderedJSON.Member(key: "radius", value: number(ends, named: "circle-radius")),
            OrderedJSON.Member(
              key: "strokeWidth", value: number(ends, named: "circle-stroke-width")),
          ]),
          "extent": .object([
            OrderedJSON.Member(
              key: "dash", value: number(try layer(extent, role: "bounds"), named: "line-dasharray")
            ),
            OrderedJSON.Member(
              key: "fillOpacity",
              value: number(try layer(extent, role: "bounds-fill"), named: "fill-opacity")),
            OrderedJSON.Member(
              key: "width", value: number(try layer(extent, role: "bounds"), named: "line-width")),
          ]),
          "halo": .object([
            OrderedJSON.Member(key: "blur", value: number(halo, named: "line-blur")),
            OrderedJSON.Member(key: "opacity", value: number(halo, named: "line-opacity")),
            OrderedJSON.Member(key: "width", value: number(halo, named: "line-width")),
          ]),
          "line": .object([
            OrderedJSON.Member(
              key: "width", value: number(try layer(line, role: "line"), named: "line-width"))
          ]),
          "pin": .object([
            OrderedJSON.Member(
              key: "iconSize", value: number(pin, named: "icon-size", paint: false))
          ]),
          "placeFallbackGlyph": try glyph(fallback),
          "placeGlyph": try glyph(place),
          "sourceId": .string(place.sourceId),
        ])
    }
  }

  /// highlight reads a picked result as the fixture writes it, by its `kind`.
  static func highlight(_ written: OrderedJSON) throws(FixtureError) -> SearchHighlight {
    func numbers(_ key: String) throws(FixtureError) -> [Double]? {
      guard let value = written[key], !value.isNull else { return nil }
      return try value.numberList(naming: key)
    }
    switch try written.string(at: "kind") {
    case "place":
      return .place(point: try written.numbers(at: "point"))
    case "poi":
      return .poi(
        point: try written.numbers(at: "point"),
        category: try written.optionalString(at: "category").map(
          DataSchema.POICategory.init(rawValue:)))
    case "way":
      return .way(
        anchor: try written.numbers(at: "anchor"), bounds: try numbers("bounds"),
        coordinates: written["coordinates"] == nil ? nil : try written.positions(at: "coordinates"))
    case let kind:
      throw FixtureError(description: "`\(kind)` is no kind of picked result")
    }
  }

  /// written writes a feature collection as RFC 7946 writes one, each feature's properties an
  /// object.
  static func written(_ collection: GeoJSONFeatureCollection) -> OrderedJSON {
    .object([
      OrderedJSON.Member(
        key: "features",
        value: .array(
          collection.features.map { feature in
            .object([
              OrderedJSON.Member(
                key: "geometry", value: feature.geometry.map(GeoFixtures.written) ?? .null),
              OrderedJSON.Member(key: "properties", value: GeoFixtures.ordered(feature.properties)),
              OrderedJSON.Member(key: "type", value: .string("Feature")),
            ])
          })),
      OrderedJSON.Member(key: "type", value: .string("FeatureCollection")),
    ])
  }
}
