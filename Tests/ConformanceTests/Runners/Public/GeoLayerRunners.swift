import Foundation
import GateSupport
import MountayaClient
import MountayaGeo

extension PublicRunners {
  /// layersOrder answers the rank the case's tile `layer` draws at. The rank table, the points of
  /// interest's source layers and the twelve bands are held to the ones Geo publishes, each band by
  /// its `LayerRank` case's words in kebab case. `poiSourceLayers` is the same members written as a
  /// set, an array whose order says nothing, so it is held to the published list as a set: the
  /// fixture's own order is stated back where the two hold the same members, and the published
  /// list, which then fails the comparison, where they do not.
  static let layersOrder = Runner(id: "geo.layers.order", table: .public) { fixture, fixtureCase in
    let written = fixture.constants?["poiSourceLayers"]?.elements?.compactMap(\.stringValue) ?? []
    let asSet =
      written.count == poiSourceLayers.count && Set(written) == Set(poiSourceLayers)
      ? written : poiSourceLayers
    try fixture.holdConstants(
      [:],
      values: [
        "layerRankBands": .object(
          LayerRank.allCases.map {
            OrderedJSON.Member(
              key: kebabCase(String(describing: $0)), value: .number(Double($0.rank)))
          }),
        "poiSourceLayerNames": GeoFixtures.texts(poiSourceLayers),
        "poiSourceLayers": GeoFixtures.texts(asSet),
        "tileSourceLayerRanks": .object(
          tileSourceLayerRanks.sorted { $0.key < $1.key }.map {
            OrderedJSON.Member(key: $0.key, value: .number(Double($0.value)))
          }),
      ])
    guard let layer = fixtureCase.input["layer"] else {
      throw FixtureError(description: "the case has no `layer`")
    }
    return .value(.number(Double(tileLayerRank(try GeoTileFixtures.layer(layer)))))
  }

  /// kebabCase writes a lowerCamelCase name in kebab case: `itineraryLine` as `itinerary-line`.
  private static func kebabCase(_ name: String) -> String {
    name.unicodeScalars.reduce(into: "") { text, scalar in
      if ("A"..."Z").contains(scalar) {
        text += "-" + String(scalar).lowercased()
      } else {
        text.unicodeScalars.append(scalar)
      }
    }
  }

  /// layersPaintZoomRange answers the window the case's `sources` paint across, as `minzoom` and
  /// `maxzoom`, or null. Each source and layer is built as the Tile API's, with the zooms the
  /// fixture writes and a placeholder in every member it leaves out.
  static let layersPaintZoomRange = Runner(id: "geo.layers.paint-zoom-range", table: .public) {
    _, fixtureCase in
    var sources: [TileSchema.TileSource] = []
    for source in try fixtureCase.input.array(at: "sources") {
      sources.append(try GeoTileFixtures.source(source))
    }
    guard let window = paintZoomRange(sources) else { return .value(.null) }
    return .value(
      .object([
        OrderedJSON.Member(key: "maxzoom", value: .number(window.maxZoom)),
        OrderedJSON.Member(key: "minzoom", value: .number(window.minZoom)),
      ]))
  }

  /// layersDataGeojson answers the FeatureCollection the case's Data API `result` of its `kind` is
  /// drawn as. The result is read by the Data API's own decoder from the JSON the fixture writes, a
  /// cell that is no finite number read as one, as a decoder that reads JSON's non-conforming
  /// numbers hands it over; a matrix's `input` is built as the Data API's, its activity,
  /// locations, metrics, sources and destinations as the fixture writes them. The colours each
  /// kind paints in are held to the ones Geo publishes.
  static let layersDataGeojson = Runner(id: "geo.layers.data-geojson", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants(
      [:],
      values: [
        "placePointColor": .string(placePointColor),
        "poiResultPointColor": .string(poiResultPointColor),
        "suggestionAlternativeColor": .string(suggestionAlternativeColor),
        "suggestionChosenColor": .string(suggestionChosenColor),
      ])
    let input = fixtureCase.input
    guard let result = input["result"] else {
      throw FixtureError(description: "the case has no `result`")
    }
    let drawn: GeoJSONFeatureCollection
    switch try input.string(at: "kind") {
    case "isochrones":
      drawn = isochronesGeoJson(
        try GeoFixtures.decoded(DataSchema.IsochronesResult.self, from: result))
    case "directions":
      drawn = directionsGeoJson(
        try GeoFixtures.decoded(DataSchema.DirectionsResult.self, from: result))
    case "suggestions":
      let routes = try GeoFixtures.decoded(DataSchema.SuggestionsResult.self, from: result)
      if let chosen = try input.optionalInteger(at: "chosen") {
        drawn = suggestionsGeoJson(routes, chosen: chosen)
      } else {
        drawn = suggestionsGeoJson(routes)
      }
    case "places":
      drawn = placesGeoJson(try GeoFixtures.decoded(DataSchema.GeocodeResult.self, from: result))
    case "pois":
      drawn = poisGeoJson(try GeoFixtures.decoded(DataSchema.PoisResult.self, from: result))
    case "matrix":
      guard let written = input["input"] else {
        throw FixtureError(description: "a matrix case has no `input`")
      }
      drawn = matrixGeoJson(
        try matrixInput(written),
        result: try GeoFixtures.decoded(DataSchema.MatrixResult.self, from: result))
    case let kind:
      throw FixtureError(description: "`\(kind)` is no kind of answer")
    }
    return .value(
      .object([
        OrderedJSON.Member(
          key: "features",
          value: .array(
            drawn.features.map { feature in
              .object([
                OrderedJSON.Member(
                  key: "geometry", value: feature.geometry.map(GeoFixtures.written) ?? .null),
                OrderedJSON.Member(
                  key: "properties", value: GeoFixtures.ordered(feature.properties)),
                OrderedJSON.Member(key: "type", value: .string("Feature")),
              ])
            })),
        OrderedJSON.Member(key: "type", value: .string("FeatureCollection")),
      ]))
  }

  /// layersOverlayLookup answers the overlay of the case's `layers` manifest its `slug` names,
  /// among the categories of its `kind` where it names one. The manifest is the Tile API's
  /// `Layers`, written with only the members the rule reads, as the fixture's description says:
  /// each overlay is built with a placeholder in every other member and an id of its own, so the
  /// one found is answered as the entry the fixture wrote for it, and an overlay two categories
  /// hold is told apart by which it is.
  static let layersOverlayLookup = Runner(id: "geo.layers.overlay-lookup", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    guard let manifest = input["layers"] else {
      throw FixtureError(description: "the case has no `layers`")
    }
    var written: [String: OrderedJSON] = [:]
    var categories: [TileSchema.CategoryOverlays] = []
    for (at, category) in try manifest.array(at: "overlays").enumerated() {
      var children: [TileSchema.Overlay] = []
      for (place, child) in try category.array(at: "children").enumerated() {
        let id = "\(at)-\(place)"
        written[id] = child
        children.append(GeoTileFixtures.overlay(try child.string(at: "slug"), id: id))
      }
      categories.append(
        GeoTileFixtures.category(try category.string(at: "slug"), children: children))
    }
    let kind: OverlayKind?
    switch try input.optionalString(at: "kind") {
    case nil: kind = nil
    case "classic": kind = .classic
    case "enrichment": kind = .enrichment
    case let named?: throw FixtureError(description: "`\(named)` is no kind of overlay")
    }
    let found = findOverlay(
      GeoTileFixtures.layers(categories), slug: try input.string(at: "slug"), kind: kind)
    return .value(found.flatMap { written[$0.id] } ?? .null)
  }

  /// The matrix input a case writes, every member it requires among it.
  private static func matrixInput(_ written: OrderedJSON) throws(FixtureError)
    -> DataSchema.MatrixInput
  {
    func indexes(_ key: String) throws(FixtureError) -> [Int]? {
      guard let value = written[key], !value.isNull else { return nil }
      var indexes: [Int] = []
      for number in try value.numberList(naming: key) {
        guard let index = Int(exactly: number) else {
          throw FixtureError(description: "`\(key)` holds an index that is no whole number")
        }
        indexes.append(index)
      }
      return indexes
    }
    let sources = try indexes("sources")
    let destinations = try indexes("destinations")
    return DataSchema.MatrixInput(
      activity: DataSchema.ActivitySlug(rawValue: try written.string(at: "activity")),
      locations: try written.positions(at: "locations"),
      metrics: try GeoFixtures.textList(written, at: "metrics").map(
        DataSchema.MatrixMetric.init(rawValue:))
    ) {
      $0.sources = sources
      $0.destinations = destinations
    }
  }
}

/// GeoTileFixtures builds the Tile API's values a layer rule reads from what a layer fixture
/// writes, with a placeholder in every member the type requires and no layer rule reads.
enum GeoTileFixtures {
  /// The names no layer rule reads, which every overlay and category a fixture writes is given.
  static let noLocales = TileSchema.Locales(
    de: nil, en: nil, es: nil, fr: nil, it: nil, ja: nil, zh: nil)

  /// layer builds the tile layer a fixture writes: its `source_layer`, `type`, `zoom_min` and
  /// `zoom_max` as written, and a placeholder in every other member.
  static func layer(_ fields: OrderedJSON) throws(FixtureError) -> TileSchema.TileLayer {
    guard fields.members != nil else { throw FixtureError(description: "a layer is not an object") }
    return TileSchema.TileLayer(
      id: "layer", key: "", layout: nil, paint: nil,
      source_layer: try fields.optionalString(at: "source_layer") ?? "layer",
      type: TileSchema.TileLayerType(rawValue: try fields.optionalString(at: "type") ?? "line"),
      zoom_max: try fields.optionalInteger(at: "zoom_max") ?? 22,
      zoom_min: try fields.optionalInteger(at: "zoom_min") ?? 0)
  }

  /// source builds the tile source a fixture writes, its `layers` as written and a placeholder
  /// elsewhere.
  static func source(_ fields: OrderedJSON) throws(FixtureError) -> TileSchema.TileSource {
    var layers: [TileSchema.TileLayer] = []
    for written in try fields.array(at: "layers") {
      layers.append(try layer(written))
    }
    return TileSchema.TileSource(
      id: "source", layers: layers, tiles: [], type: .vector,
      zoom_max: try fields.optionalInteger(at: "zoom_max") ?? 14,
      zoom_min: try fields.optionalInteger(at: "zoom_min") ?? 0)
  }

  /// overlay builds the overlay `slug` names, `id` its id, with a placeholder in every other member.
  static func overlay(_ slug: String, id: String) -> TileSchema.Overlay {
    TileSchema.Overlay(
      capabilities: TileSchema.OverlayCapabilities(
        client: TileSchema.OverlaySupportedCapabilities(timestamp: false),
        server: TileSchema.OverlaySupportedCapabilities(timestamp: false)),
      content_type: .png, id: id, locales: noLocales, slug: slug, sources: [])
  }

  /// category builds the category `slug` names, holding `children`.
  static func category(_ slug: String, children: [TileSchema.Overlay])
    -> TileSchema.CategoryOverlays
  {
    TileSchema.CategoryOverlays(children: children, id: slug, locales: noLocales, slug: slug)
  }

  /// layers builds the manifest holding `overlays`, with a placeholder elevation, itinerary and
  /// zone layer.
  static func layers(_ overlays: [TileSchema.CategoryOverlays]) -> TileSchema.Layers {
    TileSchema.Layers(
      elevation: TileSchema.Elevation(
        id: "55763749-32b4-42d5-9f62-b6c51ef54d99", tile_size: .size512,
        url: URI(URL(fileURLWithPath: "/elevation"))),
      itineraries: overlay("itineraries", id: "itineraries"), overlays: overlays, terrains: [],
      zones: overlay("zones", id: "zones"))
  }
}
