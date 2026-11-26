import Foundation
import MountayaClient
import Testing

@testable import MountayaElements

@Suite("terrainVariantOfStyle")
struct TerrainVariantOfStyleTests {
  @Test("a document is the variant it is, and none where the two variants share it or neither is")
  func variants() throws {
    let outdoors = try BaseMapOfTests.terrain(
      "outdoors", light: "https://t.test/outdoors.json", dark: "https://t.test/outdoors-dark.json")
    let satellite = try BaseMapOfTests.terrain(
      "satellite", light: "https://t.test/satellite.json", dark: "https://t.test/satellite.json")

    #expect(
      terrainVariantOfStyle(outdoors, style: URL(string: "https://t.test/outdoors.json"))
        == .light)
    #expect(
      terrainVariantOfStyle(outdoors, style: URL(string: "https://t.test/outdoors-dark.json"))
        == .dark)
    #expect(
      terrainVariantOfStyle(satellite, style: URL(string: "https://t.test/satellite.json")) == nil)
    #expect(terrainVariantOfStyle(outdoors, style: URL(string: "https://t.test/other.json")) == nil)
    #expect(terrainVariantOfStyle(outdoors, style: nil) == nil)
  }
}
