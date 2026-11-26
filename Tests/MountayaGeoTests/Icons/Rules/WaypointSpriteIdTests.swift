import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("waypointSpriteId")
struct WaypointSpriteIdTests {
  private let hut = RestSchema.WaypointIcon.hut

  @Test("the id is the icon and the colour, written small")
  func spriteId() {
    #expect(waypointSpriteId(icon: hut, color: "#3b82f6") == "section-icon-hut-3b82f6")
    #expect(waypointSpriteId(icon: hut, color: "#3B82F6") == "section-icon-hut-3b82f6")
    #expect(
      waypointSpriteId(icon: defaultWaypointIcon, color: defaultWaypointColor)
        == "section-icon-map-pin-3b82f6")
  }

  /// One leading `#` goes and only the ASCII capitals fold; every other scalar stays as written.
  @Test("a colour is read as the hex it writes")
  func colour() {
    #expect(waypointSpriteId(icon: hut, color: "3B82F6") == "section-icon-hut-3b82f6")
    #expect(waypointSpriteId(icon: hut, color: "##ABC") == "section-icon-hut-#abc")
    #expect(waypointSpriteId(icon: hut, color: "A#B") == "section-icon-hut-a#b")
    #expect(waypointSpriteId(icon: hut, color: "#") == "section-icon-hut-")
    #expect(waypointSpriteId(icon: hut, color: "#\u{C9}") == "section-icon-hut-\u{C9}")
    // A mark after the `#` is a scalar of its own, kept, where a `Character` would hold both.
    #expect(
      scalars(waypointSpriteId(icon: hut, color: "#\u{301}A"))
        == scalars("section-icon-hut-\u{301}a"))
  }

  @Test("an icon this build does not know is written as the wire spells it")
  func unknownIcon() {
    #expect(
      waypointSpriteId(icon: RestSchema.WaypointIcon(rawValue: "yurt"), color: "#000000")
        == "section-icon-yurt-000000")
    #expect(waypointFallbackGlyph == "map-pin")
    #expect(waypointIconPrefix == "section-icon-")
  }
}
