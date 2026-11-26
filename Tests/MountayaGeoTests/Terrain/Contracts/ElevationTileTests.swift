import Testing

@testable import MountayaGeo

@Suite("ElevationTile")
struct ElevationTileTests {
  @Test("a tile named by its address holds no pixels, and two compare address and bytes")
  func address() {
    let named = ElevationTile(z: 16, x: 34017, y: 23335)
    #expect(named.pixels.isEmpty)
    #expect(named == ElevationTile(z: 16, x: 34017, y: 23335, pixels: []))
    #expect(named != ElevationTile(z: 16, x: 34017, y: 23335, pixels: [1, 2, 3]))
  }
}
