import Foundation
import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("LayersSelection")
struct LayersSelectionTests {
  private struct Refused: Error {}

  @Test("a selection holds nothing until it is given a choice")
  func empty() {
    let selection = LayersSelection()

    #expect(selection.catalogue == nil)
    #expect(selection.terrain == nil)
    #expect(selection.overlay == nil)
    #expect(selection.enrichments.isEmpty)
    #expect(selection.instant == nil, "none pinned, the clock's reading")
    #expect(selection.refusal == nil)
  }

  @Test("a selection holds the catalogue, the choices, the instant and a refusal as given")
  func members() {
    let catalogue = TileFixtures.layers([])
    let pinned = Date(timeIntervalSince1970: 1_773_576_000)
    let selection = LayersSelection(
      catalogue: catalogue, terrain: "outdoors", overlay: "slopes", enrichments: ["hillshade"],
      instant: pinned, refusal: Refused())

    #expect(selection.catalogue == catalogue)
    #expect(selection.terrain == "outdoors")
    #expect(selection.overlay == "slopes")
    #expect(selection.enrichments == ["hillshade"])
    #expect(selection.instant == pinned)
    #expect(selection.refusal is Refused)
  }
}
