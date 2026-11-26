import Testing

@testable import MountayaElements

@Suite("MapPanel")
struct MapPanelTests {
  @Test("the stack's panels are named as the stack names them, and an app's by its own name")
  func names() {
    #expect(
      [MapPanel.layers, .pois, .preferences].map(\.rawValue) == ["layers", "pois", "preferences"])
    let own: MapPanel = "filters"
    #expect(own == MapPanel(rawValue: "filters"))
    #expect(own != .layers)
  }

  @Test("two panels are one where their names are written with the same scalars")
  func scalars() {
    #expect(MapPanel(rawValue: "caf\u{E9}") != MapPanel(rawValue: "cafe\u{301}"))
    #expect(MapPanel(rawValue: "caf\u{E9}").hashValue == MapPanel(rawValue: "caf\u{E9}").hashValue)
  }
}
