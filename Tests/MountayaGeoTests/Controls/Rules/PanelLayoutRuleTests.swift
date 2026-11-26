import Testing

@testable import MountayaGeo

@Suite("panelLayout")
struct PanelLayoutRuleTests {
  @Test("a wide map lays the panel at its width, capped at the map's height less its inset")
  func wide() {
    #expect(
      panelLayout(mapWidth: 1024, mapHeight: 520, topInset: 92)
        == PanelLayout(width: 340, fill: false, maxHeight: 428, pictureHeight: 52))
  }

  @Test("a map no wider than 576 fills its width and keeps room under the panel")
  func narrow() {
    #expect(
      panelLayout(mapWidth: 576, mapHeight: 520, topInset: 92)
        == PanelLayout(width: nil, fill: true, maxHeight: 412, pictureHeight: 40))
    #expect(panelLayout(mapWidth: 577, mapHeight: 520, topInset: 92).fill == false)
  }

  @Test("a map shorter than its inset leaves no height")
  func short() {
    #expect(panelLayout(mapWidth: 800, mapHeight: 60, topInset: 92).maxHeight == 0)
  }
}
