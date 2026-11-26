import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("findOverlay")
struct FindOverlayTests {
  private let rain = TileFixtures.overlay("rain")
  private let weatherSnow = TileFixtures.overlay("snow", id: "weather-snow")
  private let pois = TileFixtures.overlay("pois")
  private let enrichmentSnow = TileFixtures.overlay("snow", id: "enrichment-snow")
  private var layers: TileSchema.Layers {
    TileFixtures.layers([
      TileFixtures.category("weather", children: [rain, weatherSnow]),
      TileFixtures.category(
        enrichmentCategorySlug,
        children: [TileFixtures.overlay("hillshade"), pois, enrichmentSnow]),
    ])
  }

  @Test("the first overlay carrying the slug is the answer")
  func first() {
    #expect(findOverlay(layers, slug: "rain") == rain)
    #expect(findOverlay(layers, slug: "snow")?.id == "weather-snow")
    #expect(findOverlay(layers, slug: "fog") == nil)
  }

  @Test("a kind named reads only the categories of that kind")
  func kind() {
    #expect(findOverlay(layers, slug: "rain", kind: .classic) == rain)
    #expect(findOverlay(layers, slug: "pois", kind: .enrichment) == pois)
    #expect(findOverlay(layers, slug: "snow", kind: .enrichment)?.id == "enrichment-snow")
    #expect(findOverlay(layers, slug: "rain", kind: .enrichment) == nil)
    #expect(findOverlay(layers, slug: "pois", kind: .classic) == nil)
  }

  /// The slug and the category's are read exactly as the manifest spells them.
  @Test("a slug is matched exactly")
  func exact() {
    #expect(findOverlay(layers, slug: "Rain") == nil)
    #expect(overlayKindOf(TileFixtures.category("Enrichment", children: [])) == .classic)
    #expect(overlayKindOf(TileFixtures.category("enrichment", children: [])) == .enrichment)
  }
}
