import Testing

@testable import MountayaElements

@Suite("MarkerPin")
struct MarkerPinTests {
  @Test("two pins are one where every member is, a glyph's centre differing from a dot's")
  func equality() {
    let hut = MarkerPin(
      diameter: 28, fill: "#123456", ringColor: "#ffffff", ringWidth: 3,
      centre: .glyph("hut", size: 16, color: "#ffffff"))

    #expect(
      hut
        == MarkerPin(
          diameter: 28, fill: "#123456", ringColor: "#ffffff", ringWidth: 3,
          centre: .glyph("hut", size: 16, color: "#ffffff")))
    #expect(
      hut
        != MarkerPin(
          diameter: 28, fill: "#123456", ringColor: "#ffffff", ringWidth: 3,
          centre: .dot(size: 8, color: "#ffffff")))
    #expect(
      hut
        != MarkerPin(
          diameter: 28, fill: nil, ringColor: "#ffffff", ringWidth: 3,
          centre: .glyph("hut", size: 16, color: "#ffffff")))
  }
}
