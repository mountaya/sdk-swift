import MountayaGeo
import Testing

@testable import MountayaElements

@Suite("readMarkerImageId")
struct ReadMarkerImageIdTests {
  private static func set(holding glyphs: [String]) throws -> GlyphSet {
    try #require(
      GlyphSet(
        name: "held", paint: .stroke,
        markup: Dictionary(uniqueKeysWithValues: glyphs.map { ($0, #"<path d="M0 0h1"/>"#) })))
  }

  private static let held = ["camping", "flag-start", "hut", "road-access-permit"]

  @Test("a waypoint's and a point of interest's ids name a glyph and the colour as written")
  func named() throws {
    let set = try Self.set(holding: Self.held)

    #expect(
      readMarkerImageId("section-icon-flag-start-E03131", in: set)
        == MarkerImage(glyph: "flag-start", color: "#E03131"))
    #expect(
      readMarkerImageId("section-icon-road-access-permit-9c36b5", in: set)
        == MarkerImage(glyph: "road-access-permit", color: "#9c36b5"))
    #expect(
      readMarkerImageId("poi-icon-camping-0b7285", in: set)
        == MarkerImage(glyph: "camping", color: "#0b7285"))
    #expect(
      readMarkerImageId("section-icon-hut-aBcDeF", in: set)
        == MarkerImage(glyph: "hut", color: "#aBcDeF"))
    #expect(markerImagePrefixes == ["section-icon-", "poi-icon-"])
  }

  @Test("an id whose tail is no glyph, a hyphen and six hexadecimal digits is left missing")
  func malformed() throws {
    let set = try Self.set(holding: Self.held + ["hut-", "-hut"])

    for id in [
      "section-icon-hut1c7ed6", "section-icon--1c7ed6", "poi-icon-camping-nothex",
      "section-icon-hut-fff", "section-icon-hut-1c7ed6a", "section-icon-hut-1c7ed", "section-icon-",
      "section-icon-hut-1c7ed6\n", "section-icon-hut-1c7eg6", "section-icon-hut-\u{FF11}c7ed6",
    ] {
      #expect(readMarkerImageId(id, in: set) == nil, "\(id)")
    }
    // The name is everything before the hyphen the digits follow, a hyphen of its own included.
    #expect(readMarkerImageId("section-icon-hut--1c7ed6", in: set)?.glyph == "hut-")
    #expect(readMarkerImageId("section-icon--hut-1c7ed6", in: set)?.glyph == "-hut")
  }

  @Test("an id under no prefix, or naming a glyph the set cannot draw, is left missing")
  func unanswered() throws {
    let set = try Self.set(holding: Self.held)

    #expect(readMarkerImageId("some-basemap-sprite", in: set) == nil)
    #expect(readMarkerImageId("Section-icon-hut-1c7ed6", in: set) == nil)
    #expect(readMarkerImageId("zone-clock-1c7ed6", in: set) == nil)
    #expect(readMarkerImageId("section-icon-mountain-1c7ed6", in: set) == nil)
    #expect(readMarkerImageId("section-icon-HUT-1c7ed6", in: set) == nil)
  }

  @Test("a name holding a line terminator names no glyph")
  func lineTerminator() throws {
    let set = try Self.set(holding: ["a\nb", "a\u{2028}b", "a\tb"])

    #expect(readMarkerImageId("poi-icon-a\nb-000000", in: set) == nil)
    #expect(readMarkerImageId("poi-icon-a\u{2028}b-000000", in: set) == nil)
    #expect(readMarkerImageId("poi-icon-a\tb-000000", in: set)?.glyph == "a\tb")
  }

  @Test("a point of interest's sprite id names its glyph and its colour's six small digits")
  func poiIconImageIds() throws {
    #expect(poiIconImageId(glyph: "mountain", color: "#5D4037") == "poi-icon-mountain-5d4037")
    #expect(poiIconImageId(glyph: "map-pin", color: "1c7ed6") == "poi-icon-map-pin-1c7ed6")
    #expect(poiIconImageId(glyph: "point", color: "#\u{C9}") == "poi-icon-point-\u{C9}")
    let set = try Self.set(holding: ["map-pin"])
    #expect(
      readMarkerImageId(poiIconImageId(glyph: "map-pin", color: "#1C7ED6"), in: set)
        == MarkerImage(glyph: "map-pin", color: "#1c7ed6"), "read back")
  }
}
