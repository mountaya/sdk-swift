import Testing

@testable import MountayaGeo

@Suite("POIStyle")
struct POIStyleTests {
  private let hut = POIStyle(glyph: "hut", color: HexColor(hex: "#ff9800"))

  @Test("two styles are equal where their glyph and colour are, and hash alike")
  func equality() {
    let copy = POIStyle(glyph: "hut", color: HexColor(hex: "#ff9800"))
    #expect(hut == copy)
    #expect(hut.hashValue == copy.hashValue)
    #expect(hut != POIStyle(glyph: "campground", color: HexColor(hex: "#ff9800")))
    #expect(hut != POIStyle(glyph: "hut", color: HexColor(hex: "#ff9801")))
    #expect(hut != POIStyle(glyph: "hut", color: HexColor(hex: "#ff9800", opacity: 0.5)))
  }

  @Test("two styles compare their texts by scalars and their opacity as the same number")
  func sameValues() {
    #expect(
      POIStyle(glyph: "caf\u{E9}", color: hut.color)
        != POIStyle(glyph: "cafe\u{301}", color: hut.color))
    let unknown = POIStyle(glyph: "hut", color: HexColor(hex: "#ff9800", opacity: .nan))
    #expect(unknown == POIStyle(glyph: "hut", color: HexColor(hex: "#ff9800", opacity: .nan)))
    #expect(
      unknown.hashValue
        == POIStyle(glyph: "hut", color: HexColor(hex: "#ff9800", opacity: .nan)).hashValue)
    #expect(
      POIStyle(glyph: "hut", color: HexColor(hex: "#ff9800", opacity: 0))
        != POIStyle(glyph: "hut", color: HexColor(hex: "#ff9800", opacity: -0.0)))
  }
}
