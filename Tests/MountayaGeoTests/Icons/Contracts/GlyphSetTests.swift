import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("GlyphSet")
struct GlyphSetTests {
  @Test("both printed sets stroke their glyphs 2 units wide in a 24-unit box, the whole table each")
  func printed() {
    for set in [GlyphSet.marker, GlyphSet.control] {
      #expect(set.paint == .stroke)
      #expect(set.strokeWidth == 2)
      #expect(set.viewBox == 24)
    }
    #expect(GlyphSet.marker.name == "marker")
    #expect(GlyphSet.control.name == "control")
    #expect(GlyphSet.marker.markup.count == 82)
    #expect(GlyphSet.control.markup.count == 166)
    #expect(GlyphSet.control.markup["zoom-in"] == #"<path d="M5 12h14" /><path d="M12 5v14" />"#)
  }

  @Test("every printed glyph is markup the glyph reader reads into shapes")
  func readable() {
    for (name, markup) in GlyphSet.marker.markup.merging(
      GlyphSet.control.markup, uniquingKeysWith: { a, _ in a })
    {
      #expect(!parseGlyph(markup).isEmpty, "\(name)")
    }
  }

  @Test("every glyph Geo's rules name stands in the marker set")
  func named() {
    let marker = GlyphSet.marker.markup

    for amenity in waypointAmenities {
      #expect(marker[amenityGlyph(amenity)] != nil, "\(amenity.rawValue)")
    }
    for kind in RoadAccessKind.allCases {
      #expect(marker[roadAccessGlyph(kind)] != nil, "\(kind.id)")
    }
    #expect(marker[waypointFallbackGlyph] != nil)
  }

  @Test("a set a host builds holds what it is given, a box of 24 and a width of 2 unless stated")
  func built() throws {
    let solid = try #require(
      GlyphSet(name: "solid", paint: .fill, markup: ["dot": "<circle r=\"1\" />"]))
    let grid = try #require(
      GlyphSet(name: "grid", paint: .stroke, strokeWidth: 1.5, viewBox: 16, markup: [:]))

    #expect(solid.name == "solid")
    #expect(solid.paint == .fill)
    #expect(solid.viewBox == 24)
    #expect(solid.strokeWidth == 2)
    #expect(solid.markup["dot"] == "<circle r=\"1\" />")
    #expect((grid.viewBox, grid.strokeWidth) == (16, 1.5))
    #expect(solid != GlyphSet.marker)
    #expect(GlyphSet(name: "outline", paint: .stroke, markup: [:])?.strokeWidth == 2)
  }

  @Test("a fill set of no width is drawn, a stroke set of none is refused")
  func noWidth() {
    #expect(GlyphSet(name: "solid", paint: .fill, strokeWidth: 0, markup: [:])?.strokeWidth == 0)
    #expect(GlyphSet(name: "solid", paint: .fill, strokeWidth: -0.0, markup: [:]) != nil)
    #expect(GlyphSet(name: "outline", paint: .stroke, strokeWidth: 0, markup: [:]) == nil)
    #expect(GlyphSet(name: "outline", paint: .stroke, strokeWidth: 0.01, markup: [:]) != nil)
  }

  @Test("two sets compare their numbers as the same numbers and their texts by scalars")
  func sameSets() throws {
    let clear = try #require(GlyphSet(name: "solid", paint: .fill, strokeWidth: 0, markup: [:]))
    let negativeClear = try #require(
      GlyphSet(name: "solid", paint: .fill, strokeWidth: -0.0, markup: [:]))
    let composed = try #require(
      GlyphSet(name: "solid", paint: .fill, markup: ["caf\u{E9}": "<path d=\"M1 1h1\"/>"]))
    let decomposed = try #require(
      GlyphSet(name: "solid", paint: .fill, markup: ["cafe\u{301}": "<path d=\"M1 1h1\"/>"]))
    let chained = try #require(GlyphSet(chaining: [.marker]))

    #expect(clear != negativeClear)
    #expect(Set([clear, negativeClear]).count == 2)
    #expect(composed != decomposed)
    #expect(
      GlyphSet(name: "caf\u{E9}", paint: .fill, markup: [:])
        != GlyphSet(name: "cafe\u{301}", paint: .fill, markup: [:]))
    #expect(
      GlyphSet(name: "solid", paint: .fill, markup: ["dot": "\u{E9}"])
        != GlyphSet(name: "solid", paint: .fill, markup: ["dot": "e\u{301}"]))
    #expect(chained == GlyphSet.marker)
    #expect(chained.hashValue == GlyphSet.marker.hashValue)
  }

  @Test("a set is refused where its name is empty, its box or its width cannot be drawn")
  func refused() {
    #expect(GlyphSet(name: "", paint: .fill, markup: [:]) == nil)
    #expect(GlyphSet(name: " ", paint: .fill, markup: [:]) != nil)
    #expect(GlyphSet(name: "solid", paint: .fill, strokeWidth: -1, markup: [:]) == nil)
    #expect(GlyphSet(name: "outline", paint: .stroke, strokeWidth: -1, markup: [:]) == nil)
    for width in [Double.infinity, -.infinity, .nan] {
      #expect(GlyphSet(name: "solid", paint: .fill, strokeWidth: width, markup: [:]) == nil)
      #expect(GlyphSet(name: "outline", paint: .stroke, strokeWidth: width, markup: [:]) == nil)
    }
    for box in [0, -24, Double.infinity, .nan, -0.0] {
      #expect(GlyphSet(name: "grid", paint: .stroke, viewBox: box, markup: [:]) == nil)
    }
  }

  @Test("a chain answers each glyph from the first set that holds it, drawn as the first set is")
  func chain() throws {
    let partial = try #require(
      GlyphSet(name: "partial", paint: .stroke, markup: ["mountain": "<path d=\"M1 1h1\"/>"]))
    let rest = try #require(
      GlyphSet(
        name: "rest", paint: .stroke,
        markup: ["hut": "<path d=\"M2 2h1\"/>", "mountain": "<path d=\"M2 2h1\"/>"]))
    let chain = try #require(GlyphSet(chaining: [partial, rest]))

    #expect(chain.markup["mountain"] == "<path d=\"M1 1h1\"/>")
    #expect(chain.markup["hut"] == "<path d=\"M2 2h1\"/>")
    #expect(chain.markup["x"] == nil)
    #expect(chain.markup.keys.sorted() == ["hut", "mountain"])
    #expect(chain.name == "partial+rest")
    #expect((chain.paint, chain.viewBox, chain.strokeWidth) == (.stroke, 24, 2))
    #expect(GlyphSet(chaining: [partial]) == partial)
    // A chain chains further as a set does, every later set held to the first.
    let longer = try #require(GlyphSet(chaining: [chain, .marker]))
    #expect(longer.name == "partial+rest+marker")
    #expect(longer.markup["hut"] == "<path d=\"M2 2h1\"/>")
    #expect(longer.markup["map-pin"] == GlyphSet.marker.markup["map-pin"])
  }

  @Test("a fill chain is drawn in the first set's box and width, whatever a later set's width")
  func fillChain() throws {
    let first = try #require(
      GlyphSet(name: "first", paint: .fill, viewBox: 16, markup: ["a": "<path d=\"M1 1h1\"/>"]))
    let second = try #require(
      GlyphSet(
        name: "second", paint: .fill, strokeWidth: 0, viewBox: 16,
        markup: ["b": "<path d=\"M2 2h1\"/>"]))
    let chain = try #require(GlyphSet(chaining: [first, second]))

    #expect((chain.paint, chain.viewBox, chain.strokeWidth) == (.fill, 16, 2))
    #expect(chain.markup.keys.sorted() == ["a", "b"])
  }

  @Test("a chain is refused where a later set differs from the first, and where it chains none")
  func chainRefused() throws {
    let solid = try #require(GlyphSet(name: "solid", paint: .fill, markup: [:]))
    let outline = try #require(GlyphSet(name: "outline", paint: .stroke, markup: [:]))
    let narrow = try #require(GlyphSet(name: "narrow", paint: .fill, viewBox: 16, markup: [:]))
    let thin = try #require(GlyphSet(name: "thin", paint: .stroke, strokeWidth: 1.5, markup: [:]))

    #expect(GlyphSet(chaining: []) == nil)
    #expect(GlyphSet(chaining: [solid, outline]) == nil)
    #expect(GlyphSet(chaining: [solid, narrow]) == nil)
    #expect(GlyphSet(chaining: [outline, thin]) == nil)
    #expect(GlyphSet(chaining: [outline, .marker, thin]) == nil)
    #expect(GlyphSet(chaining: [outline, .marker, .control]) != nil)
  }
}
