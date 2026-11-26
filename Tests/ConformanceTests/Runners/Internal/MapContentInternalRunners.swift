import Foundation
import GateSupport
import MountayaClient
import MountayaGeo

@testable import MountayaElements

extension InternalRunners {
  /// mapBasemapReplay answers what a base-map switch draws, through the engine on the scripted
  /// surface, the map built on the case's `base` and the surface loading it: `draw` is
  /// `setSpecification(_:named:)` of one vector source holding the step's layers, `clear` is
  /// `removeSpecification(named:)`, `hide` is `setLayerVisibility(_:visible:)`, and `switch` asks
  /// for each base map of `to` in order, `setStyle(_:)` to a document of its own, then has the
  /// surface load the latest or fail it as `arrives` says. `addByHand` is a layer a caller adds as
  /// one adds a layer by hand, `addLayer(_:)` of the step's `layer` drawing from a source of the
  /// caller's own, `addSource(_:)` of an empty GeoJSON source, at the step's `rank`. The state is
  /// what `MapView`'s renderer
  /// draws again on every style it loads: `base` is the base map its style is, `drawn` its layers
  /// bottom first, and `hidden` those drawn hidden. The renderer's own replay onto MapLibre's map is
  /// proven on the simulator.
  static let mapBasemapReplay = Runner(id: "map.basemap.replay", table: .internal) {
    _, fixtureCase in
    let input = fixtureCase.input
    let base = try input.string(at: "base")
    let bases = (input["bases"]?.members ?? []).map(\.key)
    let steps = try input.array(at: "steps")
    func url(_ name: String) -> URL? { URL(string: "https://tiles.test/\(name).json") }
    return try await MainActor.run { () throws -> RunnerOutcome in
      let map = MapEngine(
        client: try MapFixtures.client(), style: url(base), geolocation: InertGeolocation())
      let surface = ScriptedMapSurface(drawing: map)
      surface.loadStyle()
      for step in steps {
        switch try step.string(at: "step") {
        case "draw":
          let content = try step.string(at: "content")
          try map.setSpecification(
            try MapFixtures.specification(content, layers: try step.array(at: "layers")),
            named: content)
        case "clear":
          map.removeSpecification(named: try step.string(at: "content"))
        case "hide":
          map.setLayerVisibility(try step.string(at: "layer"), visible: false)
        case "addByHand":
          let source = try step.string(at: "source")
          guard let layer = step["layer"], layer.members != nil else {
            throw FixtureError(description: "the step adds no layer")
          }
          if !map.state.sources.contains(where: { $0.id == source }) {
            map.addSource(
              MapSource(id: source, kind: .geoJson(GeoJSONFeatureCollection(features: []))))
          }
          map.addLayer(
            MapLayer(
              id: try layer.string(at: "id"),
              type: TileSchema.TileLayerType(rawValue: try layer.string(at: "type")),
              source: source, rank: try step.integer(at: "rank")))
        case "switch":
          for name in try GeoFixtures.textList(step, at: "to") {
            map.setStyle(url(name))
          }
          if try step.flag(at: "arrives") {
            surface.loadStyle()
          } else {
            surface.failStyle()
          }
        case let other:
          throw FixtureError(description: "no step is called `\(other)`")
        }
      }
      guard let shown = bases.first(where: { url($0) == map.state.style }) else {
        throw FixtureError(description: "the map shows no base map the case names")
      }
      let drawn = map.state.layers
      return .value(
        .object([
          OrderedJSON.Member(key: "base", value: .string(shown)),
          OrderedJSON.Member(key: "drawn", value: GeoFixtures.texts(drawn.map(\.id))),
          OrderedJSON.Member(
            key: "hidden", value: GeoFixtures.texts(drawn.filter(\.isHidden).map(\.id))),
        ]))
    }
  }
}

extension InternalRunners {
  /// mapRoadAccessLayers answers the layers an itinerary source's restricted stretches are drawn on,
  /// through the internal rule the engine applies, each with its rank and the layer as MapLibre's
  /// style specification writes it. The constants are held to the rule's own: the kinds most
  /// severe first, each kind's colour and glyph, the stripe image's head, the stripes' opacity,
  /// the icons' size, the width of a line stating none, the source layer and the two bands. A
  /// plain map draws the same layers beside the itinerary it is handed, with the host's word on
  /// whether the stretches are shown, which the runner holds the engine to.
  static let mapRoadAccessLayers = Runner(id: "map.road-access.layers", table: .internal) {
    fixture, fixtureCase in
    try fixture.holdConstants(
      [
        "iconSize": roadAccessIconSize,
        "stripeOpacity": roadAccessStripeOpacity,
        "unstatedLineWidth": unstatedLineWidth,
      ],
      values: [
        "kinds": GeoFixtures.texts(RoadAccessKind.allCases.map(\.id)),
        "kindStyles": .object(
          RoadAccessKind.allCases.map { kind in
            OrderedJSON.Member(
              key: kind.id,
              value: .object([
                OrderedJSON.Member(key: "color", value: .string(roadAccessColor(kind).hex)),
                OrderedJSON.Member(key: "glyph", value: .string(roadAccessGlyph(kind))),
              ]))
          }),
        "ranks": .object([
          OrderedJSON.Member(key: "icons", value: .number(Double(LayerRank.itineraryPoint.rank))),
          OrderedJSON.Member(
            key: "stripes", value: .number(Double(LayerRank.itineraryRestriction.rank))),
        ]),
        "sourceLayer": .string(itineraryRestrictionSourceLayer),
        "stripeImagePrefix": .string(roadAccessStripeImagePrefix),
      ])
    let input = fixtureCase.input
    let source = try GeoFixtures.decoded(TileSchema.TileSource.self, from: input["source"] ?? .null)
    let shown = try input.flag(at: "shown")
    let layers = roadAccessLayersOf(source, isShown: shown)
    try await MainActor.run { () throws in
      let map = MapEngine(client: try MapFixtures.client(), geolocation: InertGeolocation())
      map.setAccessRestrictionsVisibility(shown)
      try map.setSpecification(
        TileSchema.TileSpecification(sources: [source]), named: "itinerary")
      let drawn = map.state.layers.filter { $0.sourceLayer == itineraryRestrictionSourceLayer }
      guard drawn.map(MapFixtures.styleLayer) == layers.map(MapFixtures.styleLayer),
        drawn.map(\.rank) == layers.map(\.rank)
      else {
        throw FixtureError(description: "the map drew other stretches: \(drawn.map(\.id))")
      }
    }
    return .value(
      .array(
        layers.map { layer in
          .object([
            OrderedJSON.Member(key: "layer", value: MapFixtures.styleLayer(layer)),
            OrderedJSON.Member(key: "rank", value: .number(Double(layer.rank))),
          ])
        }))
  }
}
