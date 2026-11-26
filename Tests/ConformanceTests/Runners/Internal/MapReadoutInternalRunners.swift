import Foundation
import GateSupport
import MountayaClient
import MountayaGeo

@testable import MountayaElements

extension InternalRunners {
  /// mapReadoutOpen answers when a map opens its readout and what it reads for it, played as a
  /// script over an exchange that answers the layers catalogue and the elevation source's TileJSON
  /// document at once, the case's `source` stated through them, and holds every tile read until a
  /// step settles it. `press` moves the camera to the case's `zoom` and long-presses at `position`,
  /// `answer` lets a tile read answer its `pixels`, `fail` answer a 404, `move` moves the camera
  /// elsewhere and `tap` taps the map. A tile's image is read by a decoder of the script's own,
  /// which reads the pixels the case writes, since the fixture's tiles are no image a platform's
  /// codec reads. A press sends its tile reads in the order `elevationTilesAt` answers them, and the
  /// reads are numbered in the order the exchange received them, as `sdk/SPEC.md` §15 has a runner
  /// number them, so the order the engine sends them in is the order the case holds. A `move` is
  /// the reader's, which closes the readout as it begins, `readerMoveBegan()`, the camera then
  /// coming to rest elsewhere, and a `tap` is a tap the renderer tells. A step settling a read the
  /// map withdrew, its readout since closed or replaced, lands nowhere, as the read waits on
  /// nothing any more. Every call runs on the main actor, and each step settles before the next.
  /// The detail zoom is held to Geo's.
  static let mapReadoutOpen = Runner(id: "map.readout.open", table: .internal) {
    fixture, fixtureCase in
    try fixture.holdConstants(["detailZoom": readoutDetailZoom])
    guard #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) else {
      throw Unsimulated()
    }
    return try await MapReadoutScripts.open(fixtureCase.input)
  }
}

/// MapReadoutScripts plays the readout's scripts.
@MainActor
enum MapReadoutScripts {
  /// GridPixels reads a tile's image as the script writes one: its rows of `[R, G, B]` as JSON.
  struct GridPixels: ElevationImageDecoding {
    func pixels(of image: Data, edge: Int) -> [UInt8]? {
      guard let grid = try? OrderedJSON.parse(String(decoding: image, as: UTF8.self)),
        let bytes = try? GeoTerrainFixtures.pixels(grid), bytes.count == edge * edge * 3
      else { return nil }
      return bytes
    }
  }

  /// Source is an exchange that answers the layers catalogue and the elevation source's TileJSON
  /// at once and hands every other request to `held`.
  @MainActor
  final class Source: HTTPExchange {
    let held: MapFixtures.Held
    let catalogue: Data
    let document: Data
    private(set) var served = 0

    init(held: MapFixtures.Held, catalogue: Data, document: Data) {
      self.held = held
      self.catalogue = catalogue
      self.document = document
    }

    func send(_ request: ExchangeRequest) async throws -> ExchangeResponse {
      let path = request.url.path
      if path.hasSuffix("/v1/tile-layers") || path.hasSuffix("/v1/elevation/tiles.json") {
        served += 1
        return ExchangeResponse(
          status: 200, headers: ["Content-Type": "application/json"],
          body: ExchangeBody(path.hasSuffix("tiles.json") ? document : catalogue))
      }
      return try await held.send(request)
    }
  }

  /// open plays `map.readout.open`'s steps.
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  static func open(_ input: OrderedJSON) async throws -> RunnerOutcome {
    let source = input["source"] ?? .null
    let tiles = BaseURLs.standard.tiles.absoluteString
    let encoding = try source.optionalString(at: "encoding")
    let tileSize = try source.integer(at: "tileSize")
    let catalogue = Data(
      """
      {"data": {
        "elevation": {"id": "elevation", "tile_size": \(tileSize),
          "url": "\(tiles)/v1/elevation/tiles.json"},
        "itineraries": \(MapReadoutScripts.emptyOverlay), "zones": \(MapReadoutScripts.emptyOverlay),
        "overlays": [], "terrains": []}}
      """.utf8)
    let document = Data(
      """
      {"tilejson": "3.0.0", \(encoding.map { #""encoding": "\#($0)", "# } ?? "")
        "maxzoom": \(try source.integer(at: "zoom")), "minzoom": 0,
        "tiles": ["\(tiles)/v1/elevation/{z}/{x}/{y}"]}
      """.utf8)
    let held = MapFixtures.Held()
    let exchange = Source(held: held, catalogue: catalogue, document: document)
    let map = MapEngine(
      client: try MapFixtures.client(
        credential: .publishable(key: "pk_conformance"), retry: try RetryPolicy(maxRetries: 0),
        exchange: exchange),
      geolocation: InertGeolocation())
    map.elevation.decoder = GridPixels()
    map.isReadoutOn = try input.flag(at: "readout")
    func progress() -> [Double] {
      [Double(exchange.served), map.readout?.facts.terrain?.elevation ?? -1]
        + held.progress.map(Double.init)
    }
    /// settle lets the read `read`, numbered in the order the exchange received it, answer as
    /// `answer` says, or does nothing where the map withdrew it.
    func settle(_ read: Int, answer: (Int) throws -> Void) throws {
      guard held.reads.indices.contains(read) else {
        throw FixtureError(description: "read \(read) was never sent")
      }
      guard !held.reads[read].cancelled else { return }
      try answer(read)
    }
    for step in try input.array(at: "steps") {
      switch try step.string(at: "step") {
      case "press":
        let position = try step.numbers(at: "position")
        map.cameraMoved(
          to: CameraPose(center: position, zoom: try step.number(at: "zoom"), pitch: 0, bearing: 0))
        map.longTapped(at: [0, 0], position: position)
      case "answer":
        let pixels = Data((step["pixels"] ?? .null).serialized().utf8)
        try settle(try step.integer(at: "read")) { try held.answer($0, body: pixels) }
      case "fail":
        try settle(try step.integer(at: "read")) { try held.fail($0) }
      case "move":
        map.readerMoveBegan()
        map.cameraMoved(to: CameraPose(center: [0, 0], zoom: 2, pitch: 0, bearing: 0))
      case "tap":
        map.tapped(at: [0, 0], position: [0, 0])
      case let other:
        throw FixtureError(description: "no step is called `\(other)`")
      }
      await MainQueue.settle { progress() }
    }
    let reads = held.reads.map { read -> OrderedJSON in
      let address = tile(read)
      return .object([
        OrderedJSON.Member(key: "x", value: .number(Double(address[1]))),
        OrderedJSON.Member(key: "y", value: .number(Double(address[2]))),
        OrderedJSON.Member(key: "z", value: .number(Double(address[0]))),
      ])
    }
    var open: OrderedJSON = .null
    if let readout = map.readout {
      open = .object([
        OrderedJSON.Member(key: "position", value: GeoFixtures.numbers(readout.position)),
        OrderedJSON.Member(
          key: "terrain", value: GeoTerrainFixtures.terrain(readout.facts.terrain)),
      ])
    }
    held.release()
    await MainQueue.settle { progress() }
    map.close()
    return .value(
      .object([
        OrderedJSON.Member(key: "open", value: open),
        OrderedJSON.Member(key: "reads", value: .array(reads)),
      ]))
  }

  /// tile reads the address a tile read asked for, `[z, x, y]`, off its path.
  private static func tile(_ read: MapFixtures.Held.Read) -> [Int] {
    read.request.url.pathComponents.suffix(3).compactMap { Int($0) }
  }

  /// emptyOverlay is a catalogue's overlay of no source.
  static let emptyOverlay = #"""
    {"capabilities": {"client": {"timestamp": false}, "server": {"timestamp": false}},
      "content_type": "application/x-protobuf", "id": "none", "locales": {}, "slug": "none",
      "sources": []}
    """#
}
