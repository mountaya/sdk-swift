import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("activityMarkerGlyph")
struct ActivityMarkerGlyphTests {
  private static func set(holding glyphs: [String]) throws -> GlyphSet {
    try #require(
      GlyphSet(
        name: "held", paint: .stroke,
        markup: Dictionary(uniqueKeysWithValues: glyphs.map { ($0, "<path d=\"M0 0h1\"/>") })))
  }

  @Test("an activity's silhouette is its slug under the namespace, where the set holds it")
  func held() throws {
    let set = try Self.set(holding: ["activity-gravel", "activity-hiking-and-trail"])

    #expect(
      activityMarkerGlyph(RestSchema.ActivitySlug(rawValue: "gravel"), in: set) == "activity-gravel"
    )
    #expect(
      activityMarkerGlyph(.hikingAndTrail, in: set) == "activity-hiking-and-trail")
    #expect(activityMarkerPrefix == "activity-")
  }

  @Test("an activity the set holds no silhouette for names none")
  func notHeld() throws {
    #expect(activityMarkerGlyph(.hikingAndTrail, in: .marker) == nil)
    #expect(
      activityMarkerGlyph(
        RestSchema.ActivitySlug(rawValue: "hiking"), in: try Self.set(holding: ["hiking"])) == nil)
  }

  @Test("an empty slug names none, not the bare prefix")
  func empty() throws {
    #expect(
      activityMarkerGlyph(
        RestSchema.ActivitySlug(rawValue: ""), in: try Self.set(holding: ["activity-"])) == nil)
  }
}
