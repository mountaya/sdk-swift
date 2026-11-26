import Foundation
import MountayaClient
import Testing

@testable import MountayaElements

@Suite("baseMapOf")
struct BaseMapOfTests {
  static func terrain(_ slug: String, light: String, dark: String) throws -> TileSchema.Terrain {
    let body = """
      {"id": "\(slug)", "slug": "\(slug)", "locales": {}, "variants": {
        "light": {"style": {"url": "\(light)"}, "tiles": {"size": 512, "url": "https://t.test/l"}},
        "dark": {"style": {"url": "\(dark)"}, "tiles": {"size": 512, "url": "https://t.test/d"}}}}
      """
    return try JSONDecoder().decode(TileSchema.Terrain.self, from: Data(body.utf8))
  }

  static let terrains: [TileSchema.Terrain] = {
    let outdoors = try? terrain(
      "outdoors", light: "https://t.test/outdoors.json", dark: "https://t.test/outdoors-dark.json")
    let satellite = try? terrain(
      "satellite", light: "https://t.test/satellite.json", dark: "https://t.test/satellite.json")
    return [outdoors, satellite].compactMap { $0 }
  }()

  @Test("a slug names its terrain, none the first, in the variant asked for")
  func named() throws {
    let outdoors = try #require(
      baseMapOf(Self.terrains, slug: "outdoors", variant: .light))
    #expect(outdoors.terrain.slug == "outdoors")
    #expect(outdoors.style.absoluteString == "https://t.test/outdoors.json")
    let dark = try #require(baseMapOf(Self.terrains, slug: nil, variant: .dark))
    #expect(dark.terrain.slug == "outdoors")
    #expect(dark.style.absoluteString == "https://t.test/outdoors-dark.json")
    let shared = try #require(
      baseMapOf(Self.terrains, slug: "satellite", variant: .dark))
    #expect(shared.style.absoluteString == "https://t.test/satellite.json")
    let unknown = try #require(
      baseMapOf(
        Self.terrains, slug: "outdoors", variant: TileSchema.TerrainVariant(rawValue: "dusk")))
    #expect(unknown.style.absoluteString == "https://t.test/outdoors.json", "light unless dark")
  }

  @Test("a slug the catalogue does not hold, and a catalogue of no terrain, name none")
  func none() {
    #expect(baseMapOf(Self.terrains, slug: "topo", variant: .light) == nil)
    #expect(baseMapOf([], slug: nil, variant: .light) == nil)
    #expect(baseMapOf(Self.terrains, slug: "Outdoors", variant: .light) == nil)
  }
}
