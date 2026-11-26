import MountayaGeo
import Testing

@testable import MountayaElements

@Suite("describeMarkerPin")
struct DescribeMarkerPinTests {
  private static func set() throws -> GlyphSet {
    try #require(
      GlyphSet(
        name: "held", paint: .stroke,
        markup: ["droplet": "<path d=\"M0 0h1\"/>", "hut": "<path d=\"M0 0h1\"/>"]))
  }

  @Test("no colour and no glyph is a disc in the accent, ringed in white, with a dot")
  func plain() throws {
    let pin = describeMarkerPin(color: nil, glyph: nil, in: try Self.set())

    #expect(
      pin
        == MarkerPin(
          diameter: 28, fill: nil, ringColor: "#ffffff", ringWidth: 3,
          centre: .dot(size: 8, color: "#ffffff")))
  }

  @Test("a glyph the set draws stands at the centre, on the colour named")
  func glyph() throws {
    let pin = describeMarkerPin(color: "#123456", glyph: "hut", in: try Self.set())

    #expect(pin.fill == "#123456")
    #expect(pin.centre == .glyph("hut", size: 16, color: "#ffffff"))
  }

  @Test("a glyph the set cannot draw gives way to the dot, a glyph alone stands on the accent")
  func fallbacks() throws {
    let set = try Self.set()

    #expect(
      describeMarkerPin(color: "#123456", glyph: "castle", in: set).centre
        == .dot(size: 8, color: "#ffffff"))
    #expect(describeMarkerPin(color: nil, glyph: "droplet", in: set).fill == nil)
    #expect(
      describeMarkerPin(color: nil, glyph: "droplet", in: set).centre
        == .glyph("droplet", size: 16, color: "#ffffff"))
    #expect(describeMarkerPin(color: "#e8590c", glyph: nil, in: set).fill == "#e8590c")
  }
}
