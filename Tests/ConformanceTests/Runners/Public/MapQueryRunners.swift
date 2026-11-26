import Foundation
import GateSupport
import MountayaClient
import MountayaElements
import MountayaGeo

extension PublicRunners {
  /// mapQueryLayers answers which layers each point query asks the renderer about, through the
  /// engine's `features(at:)`, `itineraries(at:)`, `pois(at:)` and `zones(at:)` on the scripted
  /// surface, which records the layers each query asked: the case's layers placed at their ranks,
  /// the live style holding its `live` ids. A query that asks nothing is null. The bands are held to
  /// `LayerRank`'s.
  static let mapQueryLayers = Runner(id: "map.query.layers", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants(
      [:],
      values: [
        "bands": .object([
          OrderedJSON.Member(
            key: "itineraryLine", value: .number(Double(LayerRank.itineraryLine.rank))),
          OrderedJSON.Member(
            key: "itineraryPoint", value: .number(Double(LayerRank.itineraryPoint.rank))),
          OrderedJSON.Member(key: "poi", value: .number(Double(LayerRank.poi.rank))),
          OrderedJSON.Member(key: "zone", value: .number(Double(LayerRank.zone.rank))),
        ])
      ])
    let input = fixtureCase.input
    let live = try GeoFixtures.textList(input, at: "live")
    return try await MainActor.run { () throws -> RunnerOutcome in
      let map = MapEngine(client: try MapFixtures.client(), geolocation: InertGeolocation())
      let surface = ScriptedMapSurface(drawing: map)
      try MapFixtures.place(input, on: map)
      surface.liveLayers = live
      @MainActor func asked(_ query: ([Double]) -> [QueriedFeature]) throws -> OrderedJSON {
        let before = surface.queries.count
        guard query([0, 0]).isEmpty else {
          throw FixtureError(description: "a query found a feature nothing drew")
        }
        guard surface.queries.count > before, let layers = surface.queries.last else {
          return .null
        }
        return GeoFixtures.texts(layers)
      }
      return .value(
        .object([
          OrderedJSON.Member(key: "features", value: try asked { map.features(at: $0) }),
          OrderedJSON.Member(key: "itineraries", value: try asked { map.itineraries(at: $0) }),
          OrderedJSON.Member(key: "pois", value: try asked { map.pois(at: $0) }),
          OrderedJSON.Member(key: "zones", value: try asked { map.zones(at: $0) }),
        ]))
    }
  }

  /// mapQueryFeatureShape answers what a point query answers for the features a renderer found,
  /// through the engine's `features(at:)` on the scripted surface: each feature the case's renderer
  /// found is built through `QueriedFeature`'s published initializer, the shape's rule, every layer
  /// that drew one placed by the map, and the query answers them as found.
  static let mapQueryFeatureShape = Runner(id: "map.query.feature-shape", table: .public) {
    _, fixtureCase in
    let rendered = try MapFixtures.features(fixtureCase.input, at: "rendered")
    return try await MainActor.run { () throws -> RunnerOutcome in
      let map = MapEngine(client: try MapFixtures.client(), geolocation: InertGeolocation())
      let surface = ScriptedMapSurface(drawing: map)
      for layer in rendered.map(\.layer) where !map.state.layers.contains(where: { $0.id == layer })
      {
        map.addLayer(
          MapLayer(
            id: layer, type: .line, source: "placed", rank: LayerRank.overlay.rank))
      }
      surface.rendered = rendered
      return .value(.array(try map.features(at: [0, 0]).map(MapFixtures.answer)))
    }
  }

  /// mapQueryElevationAt answers the elevation a map answers at the case's `lngLat`, through the
  /// engine's `elevation(at:)` over a client whose exchange answers the Data API's terrain samples
  /// with the case's `answer`, and what the map asked with: the locations of the query's input,
  /// and its selection read back off the document the query sent, each field it names selected
  /// whole. No surface is drawn, so no drawn terrain is there to read.
  static let mapQueryElevationAt = Runner(id: "map.query.elevation-at", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    guard let answer = input["answer"] else {
      throw FixtureError(description: "the input states no `answer`")
    }
    let position = try input.numbers(at: "lngLat")
    let exchange = MapFixtures.Recording(answer: .data(operation: "terrainSamples", result: answer))
    let elevation = try await MainActor.run { () throws -> MapEngine in
      MapEngine(client: try MapFixtures.client(exchange: exchange), geolocation: InertGeolocation())
    }.elevation(at: position)
    let sent = await exchange.sent
    guard let request = sent.last, let body = request.body else {
      throw FixtureError(description: "the map asked the Data API nothing")
    }
    let read = try OrderedJSON.parse(String(decoding: body, as: UTF8.self))
    guard let document = read["query"]?.stringValue,
      let locations = read["variables"]?["input"]?["locations"]
    else {
      throw FixtureError(description: "the query sent no document or no locations")
    }
    return .value(
      .object([
        OrderedJSON.Member(
          key: "asked",
          value: .object([
            OrderedJSON.Member(key: "locations", value: locations),
            OrderedJSON.Member(
              key: "select", value: try MapFixtures.selection(of: document, field: "terrainSamples")
            ),
          ])),
        OrderedJSON.Member(key: "elevation", value: elevation.map { .number($0) } ?? .null),
      ]))
  }
}

extension MapFixtures {
  /// selection reads back the fields a Data API document selects under its operation's `field`, as
  /// the fixtures write a selection: an object per level, `true` for a field selected whole. A
  /// field's arguments are read past.
  static func selection(of document: String, field: String) throws(FixtureError) -> OrderedJSON {
    var tokens: [String] = []
    var word = ""
    var arguments = 0
    for character in document {
      if character == "(" { arguments += 1 }
      if character == ")" {
        arguments -= 1
        continue
      }
      guard arguments == 0 else { continue }
      if character.isLetter || character.isNumber || character == "_" {
        word.append(character)
        continue
      }
      if !word.isEmpty {
        tokens.append(word)
        word = ""
      }
      if character == "{" || character == "}" {
        tokens.append(String(character))
      }
    }
    guard let open = tokens.firstIndex(of: "{") else {
      throw FixtureError(description: "the document selects nothing")
    }
    var index = open + 1
    func level() throws(FixtureError) -> OrderedJSON {
      var members: [OrderedJSON.Member] = []
      while index < tokens.count {
        let token = tokens[index]
        index += 1
        switch token {
        case "}":
          return .object(members)
        case "{":
          guard let last = members.popLast() else {
            throw FixtureError(description: "a selection opens with no field")
          }
          members.append(OrderedJSON.Member(key: last.key, value: try level()))
        default:
          members.append(OrderedJSON.Member(key: token, value: .bool(true)))
        }
      }
      throw FixtureError(description: "a selection is never closed")
    }
    guard let selected = try level()[field] else {
      throw FixtureError(description: "the document selects nothing under `\(field)`")
    }
    return selected
  }
}
