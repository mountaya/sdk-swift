import MountayaElements
import Testing

@Suite("MapError")
struct MapErrorTests {
  @Test("a refusal names what the command named, and says what to do")
  func names() {
    let refusal = MapError(kind: .layerNotFound, name: "route")

    #expect(refusal.kind == .layerNotFound)
    #expect(refusal.name == "route")
    #expect(refusal.description.contains("\"route\""))
    #expect(MapError(kind: .terrainNotFound, name: "moon").description.contains("getTileLayers"))
    #expect(MapError(kind: .markerNotFound, name: "hut").description.contains("\"hut\""))
    #expect(MapError(kind: .positionRefused, name: "hut").description.contains("-90 to 90"))
    #expect(
      MapError(kind: .maxBoundsRefused, name: "[5.0, 45.0, 7.0, 45.0]").description.contains(
        "nil to lift the lock"))
    #expect(
      MapError(kind: .zoomBoundsRefused, name: "13.0...12.0").description.contains(
        "renderer's floor"))
    #expect(MapError(kind: .numberRefused, name: "zoom").description.contains("finite number"))
    #expect(MapError(kind: .fixRefused(.denied), name: "locate").description.contains("(denied)"))
    #expect(MapError(kind: .closed, name: "locate").description.contains("closed map"))
    #expect(MapError(kind: .typeRefused, name: "geojson").description.contains("\"geojson\""))
    #expect(MapError(kind: .overlayNotFound, name: "snow").description.contains("getTileLayers"))
    #expect(MapError(kind: .kindMismatch, name: "slope").description.contains("addEnrichment"))
    #expect(MapError(kind: .analysisNotFound, name: "a").description.contains("\"a\""))
    #expect(MapError(kind: .noInput, name: "a").description.contains("no input"))
  }

  @Test("the refusals of map content are each their own kind")
  func contentKinds() {
    let kinds: [MapError.Kind] = [
      .typeRefused, .overlayNotFound, .kindMismatch, .analysisNotFound, .noInput, .layerNotFound,
    ]
    for (index, kind) in kinds.enumerated() {
      for other in kinds[(index + 1)...] {
        #expect(MapError(kind: kind, name: "a") != MapError(kind: other, name: "a"))
      }
    }
  }

  @Test("a refused fix names the reason the device gave, and each reason is its own kind")
  func fixRefused() {
    #expect(
      MapError(kind: .fixRefused(.denied), name: "locate")
        != MapError(kind: .fixRefused(.unavailable), name: "locate"))
    #expect(
      MapError(kind: .fixRefused(.noApi), name: "locate")
        == MapError(kind: .fixRefused(.noApi), name: "locate"))
    #expect(
      MapError(kind: .closed, name: "locate") != MapError(kind: .numberRefused, name: "locate"))
  }

  @Test("two refusals are equal where they are of one kind and name the same, by its scalars")
  func equality() {
    #expect(MapError(kind: .layerNotFound, name: "a") == MapError(kind: .layerNotFound, name: "a"))
    #expect(
      MapError(kind: .layerNotFound, name: "a") != MapError(kind: .terrainNotFound, name: "a"))
    #expect(
      MapError(kind: .layerNotFound, name: "caf\u{E9}")
        != MapError(kind: .layerNotFound, name: "cafe\u{301}"))
  }
}
