import MountayaGeo
import Testing

@testable import MountayaElements

@Suite("describeMarkerSprite")
struct DescribeMarkerSpriteTests {
  private static func set(
    _ paint: GlyphSet.Paint, width: Double = 2, box: Double = 24, holding glyphs: [String]
  ) throws -> GlyphSet {
    try #require(
      GlyphSet(
        name: "held", paint: paint, strokeWidth: width, viewBox: box,
        markup: Dictionary(uniqueKeysWithValues: glyphs.map { ($0, #"<path d="M0 0h1"/>"#) })))
  }

  private static func sprite(fill: String, scale: Double) -> MarkerSprite {
    MarkerSprite(
      size: 48,
      disc: MarkerSprite.Disc(
        center: [24, 24], radius: 21, fill: fill, borderColor: "#ffffff", borderWidth: 3),
      glyph: MarkerSprite.GlyphFit(offset: 12, scale: scale, color: "#ffffff"))
  }

  @Test("a sprite is a 48-pixel disc of radius 21 under a 3-pixel white border, the glyph white")
  func sprite() throws {
    #expect(
      describeMarkerSprite(
        "hut", color: "#0b7285", in: try Self.set(.fill, holding: ["hut"]))
        == Self.sprite(fill: "#0b7285", scale: 1))
    // The border, centred on the disc's edge, stands whole inside the image, a pixel and a half
    // from its edge.
    let drawn = try #require(describeMarkerSprite("hut", color: "#000000", in: .marker))
    #expect(drawn.size / 2 - (drawn.disc.radius + drawn.disc.borderWidth / 2) == 1.5)
  }

  @Test("the glyph fills the 24-pixel square at the centre, whatever grid the set is drawn on")
  func fitted() throws {
    let grid48 = try Self.set(.stroke, width: 3, box: 48, holding: ["tent"])
    let grid16 = try Self.set(.stroke, box: 16, holding: ["flag-start"])

    #expect(
      describeMarkerSprite("tent", color: "#5f3dc5", in: grid48)
        == Self.sprite(fill: "#5f3dc5", scale: 0.5))
    #expect(
      describeMarkerSprite("flag-start", color: "#e03131", in: grid16)
        == Self.sprite(fill: "#e03131", scale: 1.5))
    for set in [grid48, grid16, GlyphSet.marker] {
      let glyph = try #require(set.markup.keys.first)
      let fit = try #require(describeMarkerSprite(glyph, color: "#000000", in: set)).glyph
      #expect(fit.scale * set.viewBox == 24)
      #expect(fit.offset * 2 + 24 == 48)
    }
  }

  @Test("the disc is filled with the colour as given, never read or rewritten")
  func colourAsGiven() throws {
    let set = try Self.set(.stroke, holding: ["hut"])

    #expect(describeMarkerSprite("hut", color: "#1C7ED6", in: set)?.disc.fill == "#1C7ED6")
    #expect(describeMarkerSprite("hut", color: "teal", in: set)?.disc.fill == "teal")
  }

  @Test("a glyph the set does not hold makes no sprite, one it holds with no shape makes one")
  func held() throws {
    #expect(
      describeMarkerSprite("tent", color: "#5f3dc5", in: try Self.set(.stroke, holding: ["hut"]))
        == nil)
    #expect(describeMarkerSprite("activity-hiking", color: "#5f3dc5", in: .marker) == nil)
    let empty = try #require(GlyphSet(name: "empty", paint: .stroke, markup: ["blank": ""]))
    #expect(describeMarkerSprite("blank", color: "#5f3dc5", in: empty) != nil)
  }
}
