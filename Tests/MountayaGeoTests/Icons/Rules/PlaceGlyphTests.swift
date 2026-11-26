import Testing

@testable import MountayaGeo

@Suite("placeGlyph")
struct PlaceGlyphTests {
  private static func set(holding glyphs: [String]) throws -> GlyphSet {
    try #require(
      GlyphSet(
        name: "held", paint: .stroke,
        markup: Dictionary(uniqueKeysWithValues: glyphs.map { ($0, "<path d=\"M0 0h1\"/>") })))
  }

  @Test("a place the set draws is marked with its own glyph")
  func own() throws {
    #expect(placeGlyph("hut", in: try Self.set(holding: ["hut", "map-pin"])) == "hut")
    #expect(placeGlyph("hut", in: try Self.set(holding: ["hut"])) == "hut")
    #expect(placeGlyph("hut", in: .marker) == "hut")
  }

  @Test("a place the set cannot draw, or that names none, is marked with the fallback pin")
  func fallback() throws {
    let set = try Self.set(holding: ["map-pin"])

    #expect(placeGlyph("hut", in: set) == "map-pin")
    #expect(placeGlyph(nil, in: set) == "map-pin")
    #expect(placeGlyph("", in: set) == "map-pin")
    #expect(placeGlyph("activity-hiking", in: .marker) == waypointFallbackGlyph)
  }

  @Test("a place whose set holds neither its glyph nor the pin is drawn as nothing")
  func nothing() throws {
    #expect(placeGlyph("hut", in: try Self.set(holding: [])) == nil)
    #expect(placeGlyph(nil, in: try Self.set(holding: ["hut"])) == nil)
  }
}
