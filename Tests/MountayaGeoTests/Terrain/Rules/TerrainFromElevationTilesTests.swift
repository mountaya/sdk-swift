import Testing

@testable import MountayaGeo

@Suite("terrainFromElevationTiles")
struct TerrainFromElevationTilesTests {
  private let source = ElevationSource(tileSize: 4, zoom: 16)

  /// flat is a tile of sixteen pixels that each stand for `pixel`.
  private func flat(_ pixel: [UInt8], x: Int = 34017, y: Int = 23335) -> ElevationTile {
    ElevationTile(z: 16, x: x, y: y, pixels: Array([[UInt8]](repeating: pixel, count: 16).joined()))
  }

  @Test("pixels that agree read their own height, on flat ground facing nowhere")
  func flatGround() throws {
    let reading = try #require(
      terrainFromElevationTiles([6.8652, 45.9237], source: source, tiles: [flat([1, 193, 56])]))
    #expect(reading.elevation == 1500)
    #expect(reading.slope == 0)
    #expect(reading.aspect == nil)
  }

  @Test("rows falling southward face south")
  func southward() throws {
    var pixels: [UInt8] = []
    for blue: UInt8 in [200, 160, 120, 80] {
      for _ in 0..<4 { pixels += [1, 169, blue] }
    }
    let tile = ElevationTile(z: 16, x: 34017, y: 23335, pixels: pixels)
    let reading = try #require(
      terrainFromElevationTiles([6.8652, 45.9237], source: source, tiles: [tile]))
    #expect(reading.aspect == 180)
    #expect(abs(reading.elevation - 899.0330747227417) < 1e-6)
  }

  @Test("a tile not at hand, one of too few bytes or another zoom's reads no terrain")
  func missing() {
    let edge = [6.8665924072265625, 45.9237]
    #expect(terrainFromElevationTiles(edge, source: source, tiles: [flat([1, 193, 56])]) == nil)
    let short = ElevationTile(z: 16, x: 34017, y: 23335, pixels: [1, 193, 56])
    #expect(terrainFromElevationTiles([6.8652, 45.9237], source: source, tiles: [short]) == nil)
    var other = flat([1, 193, 56])
    other.z = 15
    #expect(terrainFromElevationTiles([6.8652, 45.9237], source: source, tiles: [other]) == nil)
  }

  @Test("an encoding that decodes no height reads no terrain")
  func unknownEncoding() {
    let custom = ElevationSource(
      encoding: ElevationEncoding(rawValue: "custom"), tileSize: 4, zoom: 16)
    #expect(
      terrainFromElevationTiles([6.8652, 45.9237], source: custom, tiles: [flat([1, 193, 56])])
        == nil)
  }
}
