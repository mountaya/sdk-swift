import Testing

@testable import MountayaGeo

@Suite("PanelPlacement")
struct PanelPlacementTests {
  @Test("two placements are equal where they stand at the same numbers and lay out alike")
  func equality() {
    let layout = PanelLayout(width: 340, fill: false, maxHeight: 400, pictureHeight: 52)
    let placement = PanelPlacement(x: 10, y: 20, width: 340, layout: layout)
    #expect(placement == PanelPlacement(x: 10, y: 20, width: 340, layout: layout))
    #expect(placement != PanelPlacement(x: 10, y: 21, width: 340, layout: layout))
  }
}
