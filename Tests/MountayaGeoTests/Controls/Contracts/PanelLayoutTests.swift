import Testing

@testable import MountayaGeo

@Suite("PanelLayout")
struct PanelLayoutTests {
  @Test("two layouts compare every measure")
  func equality() {
    #expect(
      PanelLayout(width: 340, fill: false, maxHeight: 428, pictureHeight: 52)
        != PanelLayout(width: nil, fill: true, maxHeight: 428, pictureHeight: 40))
  }
}
