import Testing

@testable import MountayaElements

@Suite("MarkerSprite")
struct MarkerSpriteTests {
  private static func sprite(size: Double = 48, fill: String = "#5f3dc5", scale: Double = 1)
    -> MarkerSprite
  {
    MarkerSprite(
      size: size,
      disc: MarkerSprite.Disc(
        center: [24, 24], radius: 21, fill: fill, borderColor: "#ffffff", borderWidth: 3),
      glyph: MarkerSprite.GlyphFit(offset: 12, scale: scale, color: "#ffffff"))
  }

  @Test("two sprites are equal where every member is, a colour by its scalars")
  func equality() {
    #expect(Self.sprite() == Self.sprite())
    #expect(Self.sprite(fill: "#5F3DC5") != Self.sprite())
    #expect(Self.sprite(scale: 0.5) != Self.sprite())
    #expect(Self.sprite(size: .nan) == Self.sprite(size: .nan))
    #expect(Self.sprite(fill: "e\u{301}") != Self.sprite(fill: "\u{e9}"))
  }
}
