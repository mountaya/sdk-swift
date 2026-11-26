import GateSupport
import MountayaClient
import MountayaGeo

extension PublicRunners {
  /// styleMapPaint answers the paint the case's `patch` resolves to: the shipped paint with each
  /// member the patch states set on a copy through `MapPaint`'s own members, a member written null
  /// left as shipped (`MapPaintFixtures.folded(_:)`). The shipped paint is held to the one Geo
  /// publishes, `MapPaint.standard`.
  static let styleMapPaint = Runner(id: "geo.style.map-paint", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants([:], values: ["paint": MapPaintFixtures.written(.standard)])
    return .value(MapPaintFixtures.written(try MapPaintFixtures.folded(fixtureCase.input["patch"])))
  }

  /// styleItineraryStroke answers the layer the case's stroke is drawn as: its `kind` and `color`
  /// read as the `ItineraryStroke` they name, under the paint its `paint` patch resolves to, the
  /// shipped paint where it states none. The rule answers a line layer's style, its layout and its
  /// paint, so the layer is of type `line`, and its `id`, `source`, `sourceLayer` and `filter` are
  /// the case's own, written where the case states them as MapLibre's style specification names
  /// them.
  static let styleItineraryStroke = Runner(id: "geo.style.itinerary-stroke", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants([:])
    let input = fixtureCase.input
    let stroke: ItineraryStroke
    switch try input.string(at: "kind") {
    case "line": stroke = .line(color: try strokeColor(input))
    case "dashed": stroke = .dashed(color: try strokeColor(input))
    case "casing":
      guard input["color"] == nil else {
        throw FixtureError(description: "a casing takes no colour of its caller's")
      }
      stroke = .casing
    case let kind:
      throw FixtureError(description: "`\(kind)` is no stroke")
    }
    let style = itineraryStrokeStyle(stroke, paint: try MapPaintFixtures.folded(input["paint"]))
    var layer: [OrderedJSON.Member] = []
    if let filter = input["filter"] {
      layer.append(OrderedJSON.Member(key: "filter", value: filter))
    }
    layer += [
      OrderedJSON.Member(key: "id", value: .string(try input.string(at: "id"))),
      OrderedJSON.Member(key: "layout", value: GeoFixtures.ordered(style.layout)),
      OrderedJSON.Member(key: "paint", value: GeoFixtures.ordered(style.paint)),
      OrderedJSON.Member(key: "source", value: .string(try input.string(at: "source"))),
    ]
    if let sourceLayer = try input.optionalString(at: "sourceLayer") {
      layer.append(OrderedJSON.Member(key: "source-layer", value: .string(sourceLayer)))
    }
    layer.append(OrderedJSON.Member(key: "type", value: .string("line")))
    return .value(.object(layer))
  }

  /// layersIsochroneColor answers the fill of the band at the case's `index`. The ramp is held to
  /// the one Geo publishes.
  static let layersIsochroneColor = Runner(id: "geo.layers.isochrone-color", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants([:], values: ["ramp": GeoFixtures.texts(isochroneRamp)])
    return .value(.string(isochroneColor(try fixtureCase.input.integer(at: "index"))))
  }

  /// layersMatrixWidth answers the width a connector of the case's cost `value` draws at in a grid
  /// from `min` to `max`, each a number JSON may not carry decoded where it stands. The two widths
  /// are held to the ones Geo publishes.
  static let layersMatrixWidth = Runner(id: "geo.layers.matrix-width", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants(["maxWidth": matrixLineMaxWidth, "minWidth": matrixLineMinWidth])
    let input = fixtureCase.input
    return .value(
      .number(
        matrixLineWidth(
          try input.number(at: "value"), min: try input.number(at: "min"),
          max: try input.number(at: "max"))))
  }

  /// layersPoiStyle answers how a point of interest of the case's `category` is drawn, as
  /// `{color, glyph}`, or null where Geo names no style for it. The table is held to the one Geo
  /// publishes, entry by entry.
  static let layersPoiStyle = Runner(id: "geo.layers.poi-style", table: .public) {
    fixture, fixtureCase in
    var styles: [OrderedJSON.Member] = []
    for (category, style) in poiCategoryStyles.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
      styles.append(OrderedJSON.Member(key: category.rawValue, value: try poiStyle(style)))
    }
    try fixture.holdConstants([:], values: ["styles": .object(styles)])
    let category = DataSchema.POICategory(rawValue: try fixtureCase.input.string(at: "category"))
    guard let style = poiStyleOf(category) else { return .value(.null) }
    return .value(try poiStyle(style))
  }

  /// layersPoiCategory answers the Data API category the case's tile `category` reads as, or null.
  /// The table is held to the one Geo publishes, entry by entry.
  static let layersPoiCategory = Runner(id: "geo.layers.poi-category", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants(
      [:],
      values: [
        "categories": .object(
          poiTileCategories.sorted { $0.key < $1.key }.map {
            OrderedJSON.Member(key: $0.key, value: .string($0.value.rawValue))
          })
      ])
    let category = poiCategoryOf(try fixtureCase.input.string(at: "category"))
    return .value(category.map { .string($0.rawValue) } ?? .null)
  }

  /// dataRoadAccessStretches answers the pieces the case's `info` cuts from its `geometry`, each as
  /// `{geometry, kind}`: the feature's line as RFC 7946 writes it, and its `kind` property. The
  /// geometry is built as the fixture writes it, and `info` is read by REST's own decoder, as a
  /// consumer receives a segment's `road_access_info`.
  static let dataRoadAccessStretches = Runner(
    id: "geo.data.road-access-stretches", table: .public
  ) { fixture, fixtureCase in
    try fixture.holdConstants([:])
    let input = fixtureCase.input
    var geometry: GeoJSONGeometry?
    if let written = input["geometry"], !written.isNull {
      geometry = try GeoFixtures.geometry(written)
    }
    var info: [RestSchema.RoadAccessInfo]?
    if let written = input["info"], !written.isNull {
      info = try GeoFixtures.decoded([RestSchema.RoadAccessInfo].self, from: written)
    }
    var pieces: [OrderedJSON] = []
    for feature in roadAccessFeatures(geometry, info: info) {
      guard let line = feature.geometry, let kind = feature.properties["kind"] else {
        throw FixtureError(description: "a piece holds no line or names no kind")
      }
      pieces.append(
        .object([
          OrderedJSON.Member(key: "geometry", value: GeoFixtures.written(line)),
          OrderedJSON.Member(key: "kind", value: GeoFixtures.ordered(kind)),
        ]))
    }
    return .value(.array(pieces))
  }

  /// The colour a stroke's case states, a literal or an expression, as the client's `JSONValue`.
  private static func strokeColor(_ input: OrderedJSON) throws(FixtureError) -> JSONValue {
    guard let color = input["color"] else {
      throw FixtureError(description: "a line or a dashed stroke states no `color`")
    }
    return GeoFixtures.json(color)
  }

  /// A point of interest's style as the fixture writes one, `{color, glyph}`. The fixture writes a
  /// colour as `#rrggbb` alone, so a colour Geo states at another opacity fails the case.
  private static func poiStyle(_ style: POIStyle) throws(FixtureError) -> OrderedJSON {
    guard sameNumber(style.color.opacity, 1) else {
      throw FixtureError(
        description: "the glyph `\(style.glyph)` is drawn at an opacity of \(style.color.opacity)")
    }
    return .object([
      OrderedJSON.Member(key: "color", value: .string(style.color.hex)),
      OrderedJSON.Member(key: "glyph", value: .string(style.glyph)),
    ])
  }
}

/// MapPaintFixtures reads a map paint's patch from what a fixture writes onto `MapPaint.standard`,
/// and writes a paint back as the fixture writes one.
///
/// A patch is set on a copy through the paint's own members, as a consumer restyles a map: a list
/// replaces the shipped one whole, a nested member set leaves its siblings, a rank band is added or
/// moved alone, and a member written null is set on nothing, the shipped value standing. A member
/// the paint holds no place for fails the case rather than being read past.
enum MapPaintFixtures {
  /// folded is `MapPaint.standard` with `patch` set on it, or `MapPaint.standard` itself where the
  /// case states no patch.
  static func folded(_ patch: OrderedJSON?) throws(FixtureError) -> MapPaint {
    var paint = MapPaint.standard
    guard let patch, !patch.isNull else { return paint }
    guard let members = patch.members else {
      throw FixtureError(description: "a patch is not an object")
    }
    for member in members where !member.value.isNull {
      switch member.key {
      case "itinerary":
        try fold(member.value, onto: &paint.itinerary)
      case "layerRanks":
        for band in try objectMembers(member.value, naming: "layerRanks") where !band.value.isNull {
          guard let number = band.value.numberValue, let rank = Int(exactly: number) else {
            throw FixtureError(description: "the band `\(band.key)` is not a whole number")
          }
          paint.layerRanks[band.key] = rank
        }
      case "segments":
        try fold(member.value, onto: &paint.segments)
      case let key:
        throw FixtureError(description: "a paint holds no member `\(key)`")
      }
    }
    return paint
  }

  /// written is a paint as the fixture writes one.
  static func written(_ paint: MapPaint) -> OrderedJSON {
    let itinerary = paint.itinerary
    return .object([
      OrderedJSON.Member(
        key: "itinerary",
        value: .object([
          OrderedJSON.Member(key: "casingColor", value: .string(itinerary.casingColor)),
          OrderedJSON.Member(key: "casingOpacity", value: .number(itinerary.casingOpacity)),
          OrderedJSON.Member(
            key: "casingWidthStops", value: GeoFixtures.numbers(itinerary.casingWidthStops)),
          OrderedJSON.Member(key: "dashArray", value: GeoFixtures.numbers(itinerary.dashArray)),
          OrderedJSON.Member(key: "dashedOpacity", value: .number(itinerary.dashedOpacity)),
          OrderedJSON.Member(
            key: "lineWidthStops", value: GeoFixtures.numbers(itinerary.lineWidthStops)),
        ])),
      OrderedJSON.Member(
        key: "layerRanks",
        value: .object(
          paint.layerRanks.sorted { $0.key < $1.key }.map {
            OrderedJSON.Member(key: $0.key, value: .number(Double($0.value)))
          })),
      OrderedJSON.Member(
        key: "segments",
        value: .object([
          OrderedJSON.Member(key: "defaultColor", value: .string(paint.segments.defaultColor)),
          OrderedJSON.Member(key: "palette", value: GeoFixtures.texts(paint.segments.palette)),
        ])),
    ])
  }

  /// Sets each member an itinerary's patch states on `itinerary`.
  private static func fold(_ patch: OrderedJSON, onto itinerary: inout MapPaint.Itinerary)
    throws(FixtureError)
  {
    for member in try objectMembers(patch, naming: "itinerary") where !member.value.isNull {
      switch member.key {
      case "casingColor": itinerary.casingColor = try text(member)
      case "casingOpacity": itinerary.casingOpacity = try number(member)
      case "casingWidthStops":
        itinerary.casingWidthStops = try member.value.numberList(naming: member.key)
      case "dashArray": itinerary.dashArray = try member.value.numberList(naming: member.key)
      case "dashedOpacity": itinerary.dashedOpacity = try number(member)
      case "lineWidthStops":
        itinerary.lineWidthStops = try member.value.numberList(naming: member.key)
      case let key:
        throw FixtureError(description: "an itinerary's paint holds no member `\(key)`")
      }
    }
  }

  /// Sets each member a segments' patch states on `segments`.
  private static func fold(_ patch: OrderedJSON, onto segments: inout MapPaint.Segments)
    throws(FixtureError)
  {
    for member in try objectMembers(patch, naming: "segments") where !member.value.isNull {
      switch member.key {
      case "defaultColor":
        segments.defaultColor = try text(member)
      case "palette":
        segments.palette = try GeoFixtures.textList(patch, at: member.key)
      case let key:
        throw FixtureError(description: "a segment's paint holds no member `\(key)`")
      }
    }
  }

  private static func objectMembers(_ value: OrderedJSON, naming what: String)
    throws(FixtureError) -> [OrderedJSON.Member]
  {
    guard let members = value.members else {
      throw FixtureError(description: "`\(what)` is not an object")
    }
    return members
  }

  private static func text(_ member: OrderedJSON.Member) throws(FixtureError) -> String {
    guard let text = member.value.stringValue else {
      throw FixtureError(description: "`\(member.key)` is not a string")
    }
    return text
  }

  private static func number(_ member: OrderedJSON.Member) throws(FixtureError) -> Double {
    guard let number = member.value.numberValue else {
      throw FixtureError(description: "`\(member.key)` is not a number")
    }
    return number
  }
}
