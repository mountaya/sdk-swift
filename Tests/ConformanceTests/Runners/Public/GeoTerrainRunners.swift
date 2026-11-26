import GateSupport
import MountayaClient
import MountayaGeo

extension PublicRunners {
  /// terrainAspectCardinal answers the compass direction the case's `degrees` face, as the
  /// contract spells it, or null. The fixture's directions are held to `AspectCardinal`'s, in
  /// their clockwise order, and its sector to a turn shared among them.
  static let terrainAspectCardinal = Runner(id: "geo.terrain.aspect-cardinal", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants(
      ["sectorDegrees": 360 / Double(AspectCardinal.allCases.count)],
      values: ["cardinals": GeoFixtures.texts(AspectCardinal.allCases.map(\.rawValue))])
    let cardinal = aspectCardinal(try fixtureCase.input.number(at: "degrees"))
    return .value(cardinal.map { .string($0.rawValue) } ?? .null)
  }

  /// terrainElevationDecode answers the height the case's `pixel` stands for under its `encoding`,
  /// null where it names none, or null where the encoding decodes none. The default encoding is held
  /// to the one no encoding reads as, and the encodings to the two Geo names.
  static let terrainElevationDecode = Runner(id: "geo.terrain.elevation-decode", table: .public) {
    fixture, fixtureCase in
    let probe: [UInt8] = [1, 134, 160]
    let defaultEncoding = [ElevationEncoding.mapbox, .terrarium].first {
      decodeElevation(probe, encoding: $0) == decodeElevation(probe, encoding: nil)
    }
    try fixture.holdConstants(
      [:],
      values: [
        "defaultEncoding": defaultEncoding.map { .string($0.rawValue) } ?? .null,
        "encodings": GeoFixtures.texts(
          [ElevationEncoding.mapbox, .terrarium].map(\.rawValue)),
      ])
    let input = fixtureCase.input
    let pixel = try input.numbers(at: "pixel").map { channel throws(FixtureError) in
      guard let byte = UInt8(exactly: channel) else {
        throw FixtureError(description: "a channel `\(channel)` is no byte")
      }
      return byte
    }
    let encoding = try input.optionalString(at: "encoding").map(ElevationEncoding.init(rawValue:))
    return .value(decodeElevation(pixel, encoding: encoding).map { .number($0) } ?? .null)
  }

  /// terrainElevationSample answers the tiles the case's `position` needs of its `source`, by
  /// `elevationTilesAt(_:source:)`, and the terrain read off its `tiles`, by
  /// `terrainFromElevationTiles(_:source:tiles:)`, null where it reads none. A tile's pixels are
  /// handed as their bytes, row by row. The neighbours' spacing is held to the one Geo reads at,
  /// and the mean-sphere degree to `metersPerDegreeMeanSphere`.
  static let terrainElevationSample = Runner(id: "geo.terrain.elevation-sample", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants([
      "metersPerDegreeMeanSphere": metersPerDegreeMeanSphere,
      "neighbourDegrees": terrainNeighbourDegrees,
    ])
    let input = fixtureCase.input
    let position = try input.numbers(at: "position")
    let source = try GeoTerrainFixtures.source(input["source"] ?? .null)
    let tiles = try input.array(at: "tiles").map { written throws(FixtureError) in
      try GeoTerrainFixtures.tile(written)
    }
    let reads = elevationTilesAt(position, source: source).map { tile in
      OrderedJSON.object([
        OrderedJSON.Member(key: "x", value: .number(Double(tile.x))),
        OrderedJSON.Member(key: "y", value: .number(Double(tile.y))),
        OrderedJSON.Member(key: "z", value: .number(Double(tile.z))),
      ])
    }
    let terrain = terrainFromElevationTiles(position, source: source, tiles: tiles)
    return .value(
      .object([
        OrderedJSON.Member(key: "reads", value: .array(reads)),
        OrderedJSON.Member(key: "terrain", value: GeoTerrainFixtures.terrain(terrain)),
      ]))
  }
}

/// GeoTerrainFixtures reads the terrain fixtures' sources and tiles into Geo's values, and writes a
/// reading back as they expect one.
enum GeoTerrainFixtures {
  /// source reads a source, `{ encoding, tileSize, zoom }`, its encoding null for none.
  static func source(_ written: OrderedJSON) throws(FixtureError) -> ElevationSource {
    ElevationSource(
      encoding: try written.optionalString(at: "encoding").map(ElevationEncoding.init(rawValue:))
        ?? .mapbox,
      tileSize: try written.integer(at: "tileSize"), zoom: try written.integer(at: "zoom"))
  }

  /// tile reads a tile, `{ z, x, y, pixels }`, its pixels rows of `[R, G, B]` into their bytes.
  static func tile(_ written: OrderedJSON) throws(FixtureError) -> ElevationTile {
    ElevationTile(
      z: try written.integer(at: "z"), x: try written.integer(at: "x"),
      y: try written.integer(at: "y"), pixels: try pixels(written["pixels"] ?? .null))
  }

  /// pixels reads a grid of pixels, rows of `[R, G, B]`, into its bytes, row by row.
  static func pixels(_ written: OrderedJSON) throws(FixtureError) -> [UInt8] {
    guard let rows = written.elements else {
      throw FixtureError(description: "`pixels` is no list of rows")
    }
    var bytes: [UInt8] = []
    for row in rows {
      for pixel in row.elements ?? [] {
        for channel in pixel.elements ?? [] {
          guard let byte = channel.numberValue.flatMap({ UInt8(exactly: $0) }) else {
            throw FixtureError(description: "a channel of `pixels` is no byte")
          }
          bytes.append(byte)
        }
      }
    }
    return bytes
  }

  /// terrain writes a reading, `{ aspect, elevation, slope }`, or null.
  static func terrain(_ reading: TerrainReading?) -> OrderedJSON {
    guard let reading else { return .null }
    return .object([
      OrderedJSON.Member(key: "aspect", value: reading.aspect.map { .number($0) } ?? .null),
      OrderedJSON.Member(key: "elevation", value: .number(reading.elevation)),
      OrderedJSON.Member(key: "slope", value: .number(reading.slope)),
    ])
  }
}
