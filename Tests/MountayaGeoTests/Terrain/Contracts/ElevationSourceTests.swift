import Testing

@testable import MountayaGeo

@Suite("ElevationSource")
struct ElevationSourceTests {
  @Test("a source names mapbox where it is handed no encoding")
  func defaults() {
    let source = ElevationSource(tileSize: 512, zoom: 12)
    #expect(source.encoding == .mapbox)
    #expect(source == ElevationSource(encoding: .mapbox, tileSize: 512, zoom: 12))
    #expect(source != ElevationSource(encoding: .terrarium, tileSize: 512, zoom: 12))
  }
}
