import Testing

@testable import MountayaGeo

@Suite("MapViewport")
struct MapViewportTests {
  @Test("two viewports are equal when their center and zoom are, and hash alike")
  func equality() {
    let viewport = MapViewport(center: [8.2275, 46.8182], zoom: 6)
    #expect(viewport == MapViewport(center: [8.2275, 46.8182], zoom: 6))
    #expect(viewport.hashValue == MapViewport(center: [8.2275, 46.8182], zoom: 6).hashValue)
    #expect(viewport != MapViewport(center: [8.2275, 46.8182], zoom: 5))
    #expect(viewport != MapViewport(center: [46.8182, 8.2275], zoom: 6))
  }

  /// Equal values hash alike: a zoom of -0 is another viewport than one of 0, and a NaN zoom is the
  /// same as itself, which a synthesized `==` would answer the other way round.
  @Test("two viewports compare their numbers as the same numbers")
  func sameNumbers() {
    #expect(MapViewport(center: [0, 0], zoom: 0) != MapViewport(center: [0, 0], zoom: -0.0))
    #expect(MapViewport(center: [0, 0], zoom: 0) != MapViewport(center: [-0.0, 0], zoom: 0))
    #expect(MapViewport(center: [0, 0], zoom: .nan) == MapViewport(center: [0, 0], zoom: .nan))
    #expect(
      MapViewport(center: [.nan, 0], zoom: .nan).hashValue
        == MapViewport(center: [.nan, 0], zoom: .nan).hashValue)
    #expect(
      Set([
        MapViewport(center: [.nan, 0], zoom: .nan), MapViewport(center: [.nan, 0], zoom: .nan),
      ]).count == 1)
  }

  @Test("the center is written longitude first")
  func description() {
    #expect(
      String(describing: MapViewport(center: [8.2275, 46.8182], zoom: 6))
        == "MapViewport(center: [8.2275, 46.8182], zoom: 6.0)")
  }
}
