import Testing

@testable import MountayaGeo

@Suite("elevationTilesAt")
struct ElevationTilesAtTests {
  private let source = ElevationSource(tileSize: 4, zoom: 16)

  @Test("a point and its neighbours inside one tile need that tile alone")
  func oneTile() {
    #expect(
      elevationTilesAt([6.8652, 45.9237], source: source)
        == [ElevationTile(z: 16, x: 34017, y: 23335)])
  }

  @Test("a point near a tile's edge needs the tile beside it, ordered by x then y")
  func beside() {
    #expect(
      elevationTilesAt([6.8665924072265625, 45.9237], source: source)
        == [ElevationTile(z: 16, x: 34017, y: 23335), ElevationTile(z: 16, x: 34018, y: 23335)])
  }

  @Test("the antimeridian is crossed by whole turns")
  func antimeridian() {
    #expect(
      elevationTilesAt([179.99999, 45.9237], source: source)
        == [ElevationTile(z: 16, x: 0, y: 23335), ElevationTile(z: 16, x: 65535, y: 23335)])
  }

  @Test("a point past Web Mercator's latitude, or no point, needs no tile")
  func none() {
    #expect(elevationTilesAt([6.8652, 85.06], source: source).isEmpty)
    #expect(elevationTilesAt([.nan, 45], source: source).isEmpty)
    #expect(elevationTilesAt([6], source: source).isEmpty)
    #expect(elevationTilesAt([6, 45], source: ElevationSource(tileSize: 0, zoom: 16)).isEmpty)
  }
}
