import Foundation
import GateSupport
import MountayaClient
import MountayaElements
import MountayaGeo

extension MapFixtures {
  /// styleSource writes a source the map draws as MapLibre's style specification writes it:
  /// `{type, tiles, minzoom, maxzoom}`, with `tileSize` for a raster one that states it and its
  /// `attribution` where it states one.
  static func styleSource(_ source: MapSource) -> OrderedJSON {
    var members: [OrderedJSON.Member] = []
    if let attribution = source.attribution {
      members.append(OrderedJSON.Member(key: "attribution", value: .string(attribution)))
    }
    func tiled(_ type: String, tiles: [String], size: Int?, zoom: ZoomBounds) {
      members.append(OrderedJSON.Member(key: "maxzoom", value: .number(zoom.maxZoom)))
      members.append(OrderedJSON.Member(key: "minzoom", value: .number(zoom.minZoom)))
      if let size {
        members.append(OrderedJSON.Member(key: "tileSize", value: .number(Double(size))))
      }
      members.append(OrderedJSON.Member(key: "tiles", value: GeoFixtures.texts(tiles)))
      members.append(OrderedJSON.Member(key: "type", value: .string(type)))
    }
    switch source.kind {
    case .vector(let tiles, let zoom): tiled("vector", tiles: tiles, size: nil, zoom: zoom)
    case .raster(let tiles, let size, let zoom):
      tiled("raster", tiles: tiles, size: size, zoom: zoom)
    case .rasterDem(let tiles, let size, let zoom):
      tiled("raster-dem", tiles: tiles, size: size, zoom: zoom)
    case .geoJson:
      members.append(OrderedJSON.Member(key: "type", value: .string("geojson")))
    }
    return .object(members)
  }

  /// styleLayer writes a layer the map draws as MapLibre's style specification writes it:
  /// `{id, type, source, source-layer, filter, layout, paint, minzoom, maxzoom}`, each member it
  /// does not state left out, an empty paint and an empty layout among them.
  static func styleLayer(_ layer: MapLayer) -> OrderedJSON {
    var members: [OrderedJSON.Member] = []
    if let filter = layer.filter {
      members.append(OrderedJSON.Member(key: "filter", value: GeoFixtures.ordered(filter)))
    }
    members.append(OrderedJSON.Member(key: "id", value: .string(layer.id)))
    if !layer.layout.isEmpty {
      members.append(OrderedJSON.Member(key: "layout", value: GeoFixtures.ordered(layer.layout)))
    }
    if let zoom = layer.zoom {
      members.append(OrderedJSON.Member(key: "maxzoom", value: .number(zoom.maxZoom)))
      members.append(OrderedJSON.Member(key: "minzoom", value: .number(zoom.minZoom)))
    }
    if !layer.paint.isEmpty {
      members.append(OrderedJSON.Member(key: "paint", value: GeoFixtures.ordered(layer.paint)))
    }
    members.append(OrderedJSON.Member(key: "source", value: .string(layer.source)))
    if let sourceLayer = layer.sourceLayer {
      members.append(OrderedJSON.Member(key: "source-layer", value: .string(sourceLayer)))
    }
    members.append(OrderedJSON.Member(key: "type", value: .string(layer.type.rawValue)))
    return .object(members)
  }

  /// specification is one vector source's specification of the layers a case names, as the Tile
  /// API answers one: each with its `id`, its `key`, its id where the case names none, its
  /// `source_layer` and its `type`, at every zoom.
  static func specification(_ name: String, layers: [OrderedJSON]) throws(FixtureError)
    -> TileSchema.TileSpecification
  {
    var tileLayers: [TileSchema.TileLayer] = []
    for layer in layers {
      let id = try layer.string(at: "id")
      tileLayers.append(
        TileSchema.TileLayer(
          id: id, key: try layer.optionalString(at: "key") ?? id, layout: nil, paint: nil,
          source_layer: try layer.string(at: "source_layer"),
          type: TileSchema.TileLayerType(rawValue: try layer.string(at: "type")), zoom_max: 22,
          zoom_min: 0))
    }
    return TileSchema.TileSpecification(sources: [
      TileSchema.TileSource(
        id: name, layers: tileLayers, tiles: ["https://tiles.test/\(name)/{z}/{x}/{y}"],
        type: .vector, zoom_max: 22, zoom_min: 0)
    ])
  }

  /// specificationBody is the body the Tile API answers a specification with, `{"data": ...}`.
  static func specificationBody(_ specification: TileSchema.TileSpecification) throws -> Data {
    let written = try JSONEncoder().encode(specification)
    return Data(#"{"data": "#.utf8) + written + Data("}".utf8)
  }

  /// overlay is an overlay of the layers catalogue drawing one source of one fill layer named after
  /// its slug, at every zoom.
  static func overlay(_ slug: String) -> String {
    """
    {"capabilities": {"client": {"timestamp": false}, "server": {"timestamp": false}},
      "content_type": "application/x-protobuf", "id": "\(slug)", "locales": {}, "slug": "\(slug)",
      "sources": [{"id": "\(slug)-source", "layers": [{"id": "\(slug)-layer", "key": "\(slug)",
        "layout": null, "paint": null, "source_layer": "\(slug)", "type": "fill", "zoom_max": 22,
        "zoom_min": 0}], "tiles": ["https://tiles.test/\(slug)/{z}/{x}/{y}"], "type": "vector",
        "zoom_max": 22, "zoom_min": 0}]}
    """
  }

  /// terrain is a terrain of the layers catalogue, by its slug and the address of each variant's
  /// style.
  static func terrain(slug: String, light: String, dark: String) -> String {
    """
    {"id": "\(slug)", "slug": "\(slug)", "locales": {}, "variants": {
      "light": {"style": {"url": "\(light)"},
        "tiles": {"size": 512, "url": "https://tiles.test/\(slug)/light/tiles.json"}},
      "dark": {"style": {"url": "\(dark)"},
        "tiles": {"size": 512, "url": "https://tiles.test/\(slug)/dark/tiles.json"}}}}
    """
  }

  /// catalogueBody is the body the Tile API answers the layers catalogue with: `terrains` and the
  /// classic and enrichment overlays given, its elevation named `mark`, which tells one read's
  /// catalogue from another's.
  static func catalogueBody(
    mark: String = "elevation", terrains: [String] = [], classic: [String] = [],
    enrichment: [String] = []
  ) -> Data {
    let empty = #"""
      {"capabilities": {"client": {"timestamp": false}, "server": {"timestamp": false}},
        "content_type": "application/x-protobuf", "id": "none", "locales": {}, "slug": "none",
        "sources": []}
      """#
    let overlays =
      """
      [{"children": [\(classic.map(overlay).joined(separator: ","))], "id": "classic",
        "locales": {}, "slug": "conditions"},
       {"children": [\(enrichment.map(overlay).joined(separator: ","))], "id": "stacked",
        "locales": {}, "slug": "enrichment"}]
      """
    let body = """
      {"data": {
        "elevation": {"id": "\(mark)", "tile_size": 512, "url": "https://tiles.test/elevation.json"},
        "itineraries": \(empty), "zones": \(empty), "overlays": \(overlays),
        "terrains": [\(terrains.joined(separator: ","))]}}
      """
    return Data(body.utf8)
  }

  /// Held is an exchange that holds every request until a step of a script answers it, in the order
  /// the requests were sent, and fails one with `CancellationError` the moment its task is
  /// cancelled. It is bound to the main actor, where the map's own work runs, so a script that
  /// prefers the main queue settles every step in one order.
  @MainActor
  final class Held: HTTPExchange {
    /// Read is one request sent, and the answer it waits on while it is held.
    struct Read {
      let request: ExchangeRequest
      var answer: CheckedContinuation<ExchangeResponse, any Error>?
      var cancelled = false
    }

    private(set) var reads: [Read] = []

    func send(_ request: ExchangeRequest) async throws -> ExchangeResponse {
      let index = reads.count
      reads.append(Read(request: request))
      return try await withTaskCancellationHandler {
        try await withCheckedThrowingContinuation { continuation in
          reads[index].answer = continuation
        }
      } onCancel: {
        Task { @MainActor in self.cancel(index) }
      }
    }

    /// answer lets the read `index` answer with `body`, a success.
    func answer(_ index: Int, body: Data) throws(FixtureError) {
      try settle(index).resume(
        returning: ExchangeResponse(
          status: 200, headers: ["Content-Type": "application/json"], body: ExchangeBody(body)))
    }

    /// fail lets the read `index` answer a 404, which no attempt repeats.
    func fail(_ index: Int) throws(FixtureError) {
      try settle(index).resume(
        returning: ExchangeResponse(
          status: 404, headers: ["Content-Type": "application/json"],
          body: ExchangeBody(
            Data(#"{"errors": [{"code": "NOT_FOUND", "message": "not found"}]}"#.utf8))))
    }

    /// timeOut lets the read `index` fail as an attempt the platform gave up on at its time budget
    /// does, which no client of the scripts repeats.
    func timeOut(_ index: Int) throws(FixtureError) {
      try settle(index).resume(throwing: URLError(.timedOut))
    }

    /// release fails every read still held, as a script ends, so no read waits for ever.
    func release() {
      for index in reads.indices where reads[index].answer != nil {
        try? fail(index)
      }
    }

    /// isHeld tells whether the read `index` waits on an answer.
    func isHeld(_ index: Int) -> Bool {
      reads.indices.contains(index) && reads[index].answer != nil
    }

    /// progress is what a script reads of the exchange to know a step has come to rest: every read
    /// sent, those still held and those withdrawn.
    var progress: [Int] {
      [
        reads.count, reads.filter { $0.answer != nil }.count, reads.filter(\.cancelled).count,
      ]
    }

    private func settle(_ index: Int) throws(FixtureError)
      -> CheckedContinuation<ExchangeResponse, any Error>
    {
      guard reads.indices.contains(index), let answer = reads[index].answer else {
        throw FixtureError(description: "read \(index) was never sent, or answered already")
      }
      reads[index].answer = nil
      return answer
    }

    private func cancel(_ index: Int) {
      guard let answer = reads[index].answer else { return }
      reads[index].answer = nil
      reads[index].cancelled = true
      answer.resume(throwing: CancellationError())
    }
  }
}
