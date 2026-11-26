import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("layersPanelPress")
struct LayersPanelPressRuleTests {
  @Test("a press asks the command of its section's choice with the row's slug")
  func command() {
    let row = LayersPanelRow(slug: "snow-depth", label: "Snow depth", isChecked: false, mark: nil)

    #expect(layersPanelPress(.overlay, row: row) == .command(.overlay, slug: "snow-depth"))
    #expect(layersPanelPress(.terrain, row: row) == .command(.terrain, slug: "snow-depth"))
    #expect(
      layersPanelPress(
        .enrichment,
        row: LayersPanelRow(slug: "pois", label: "POIs", isChecked: true, mark: .tick))
        == .command(.enrichment, slug: "pois"))
  }

  @Test("a press on a row showing its lock reports the entry and selects nothing")
  func locked() {
    let row = LayersPanelRow(slug: "snow-depth", label: "Snow depth", isChecked: true, mark: .lock)

    #expect(layersPanelPress(.overlay, row: row) == .locked("snow-depth"))
  }
}
