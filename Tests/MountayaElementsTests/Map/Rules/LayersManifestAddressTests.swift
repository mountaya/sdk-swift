import Testing

@testable import MountayaElements

@Suite("layersManifestAddress")
struct LayersManifestAddressTests {
  @Test("the manifest's path is joined onto the Tile API's address, no slash doubled")
  func joined() {
    #expect(layersManifestAddress("https://tiles.test") == "https://tiles.test/v1/tile-layers")
    #expect(layersManifestAddress("https://tiles.test/") == "https://tiles.test/v1/tile-layers")
    #expect(layersManifestAddress("https://tiles.test//") == "https://tiles.test/v1/tile-layers")
    #expect(layersManifestAddress("/tiles") == "/tiles/v1/tile-layers")
    #expect(layersManifestAddress("") == "/v1/tile-layers")
    #expect(layersManifestPath == "/v1/tile-layers")
  }
}
