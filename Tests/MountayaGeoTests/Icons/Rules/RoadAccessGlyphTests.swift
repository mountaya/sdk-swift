import Testing

@testable import MountayaGeo

@Suite("roadAccessGlyph")
struct RoadAccessGlyphTests {
  @Test("a kind's glyph is the kind under the namespace, a kind of two words read whole")
  func glyph() {
    #expect(roadAccessGlyph(.permit) == "road-access-permit")
    #expect(roadAccessGlyph(.localAccess) == "road-access-local-access")
    #expect(
      RoadAccessKind.allCases.map(roadAccessGlyph) == [
        "road-access-forbidden", "road-access-private", "road-access-permit",
        "road-access-service", "road-access-local-access", "road-access-restricted",
      ])
  }
}
