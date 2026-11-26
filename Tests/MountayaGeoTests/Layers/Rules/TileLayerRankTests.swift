import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("tileLayerRank")
struct TileLayerRankTests {
  @Test("a layer draws at the rank its source layer takes")
  func ranks() {
    #expect(tileLayerRank(TileFixtures.layer("itinerary_lines")) == 50)
    #expect(tileLayerRank(TileFixtures.layer("itinerary_points")) == 90)
    #expect(tileLayerRank(TileFixtures.layer("itinerary_restrictions")) == 55)
    #expect(tileLayerRank(TileFixtures.layer("fills", type: .fill)) == 40)
    for layer in poiSourceLayers {
      #expect(tileLayerRank(TileFixtures.layer(layer)) == 80, "\(layer)")
    }
  }

  @Test("a hillshade is the terrain rank whatever its source layer")
  func hillshade() {
    let shade = TileFixtures.layer("itinerary_lines", type: .hillshade)
    #expect(tileLayerRank(shade) == LayerRank.hillshade.rank)
  }

  /// Matched exactly: another case, or another spelling of one text, is another source layer.
  @Test("a source layer the table does not know is an overlay")
  func unknown() {
    #expect(tileLayerRank(TileFixtures.layer("not_a_layer")) == 20)
    #expect(tileLayerRank(TileFixtures.layer("Itinerary_Lines")) == 20)
    #expect(
      tileLayerRank(TileFixtures.layer("cafe\u{301}"), ranks: ["caf\u{E9}": 52]) == 20)
  }

  @Test("a consumer patches the table")
  func patched() {
    var patched = tileSourceLayerRanks
    patched["my_overlay"] = LayerRank.poi.rank + 2
    #expect(tileLayerRank(TileFixtures.layer("my_overlay"), ranks: patched) == 82)
    #expect(tileLayerRank(TileFixtures.layer("itinerary_lines"), ranks: patched) == 50)
    #expect(tileLayerRank(TileFixtures.layer("itinerary_restrictions"), ranks: patched) == 55)
  }
}
