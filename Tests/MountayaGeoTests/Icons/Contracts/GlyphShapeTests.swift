import Testing

@testable import MountayaGeo

@Suite("GlyphShape")
struct GlyphShapeTests {
  @Test("two shapes are equal where they hold the same tag and attributes, whatever their order")
  func equality() {
    let one = GlyphShape(tag: "circle", attributes: ["cx": "1", "r": "2"])
    let other = GlyphShape(tag: "circle", attributes: ["r": "2", "cx": "1"])
    #expect(one == other)
    #expect(one.hashValue == other.hashValue)
    #expect(one != GlyphShape(tag: "ellipse", attributes: one.attributes))
  }

  @Test("two shapes are told apart by the scalars of their tags, names and values")
  func scalars() {
    let composed = GlyphShape(tag: "path", attributes: ["d": "\u{E9}"])
    #expect(composed == GlyphShape(tag: "path", attributes: ["d": "\u{E9}"]))
    #expect(composed.hashValue == GlyphShape(tag: "path", attributes: ["d": "\u{E9}"]).hashValue)
    #expect(composed != GlyphShape(tag: "path", attributes: ["d": "e\u{301}"]))
    #expect(composed != GlyphShape(tag: "path", attributes: ["e\u{301}": "\u{E9}"]))
    #expect(
      GlyphShape(tag: "\u{E9}", attributes: [:]) != GlyphShape(tag: "e\u{301}", attributes: [:]))
  }
}
