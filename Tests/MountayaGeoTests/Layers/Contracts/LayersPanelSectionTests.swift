import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("LayersPanelSection")
struct LayersPanelSectionTests {
  @Test("two sections are equal where every member is, a category by its scalars")
  func equality() {
    let rows = [LayersPanelRow(slug: "slopes", label: "Slope", isChecked: false, mark: nil)]
    let heading = LayersPanelHeading(word: "layers.overlays")
    let categories = [LayersPanelCategory(slug: "conditions", name: "Conditions")]
    let section = LayersPanelSection(
      heading: heading, choice: .overlay, category: "conditions", rows: rows,
      categories: categories)

    #expect(
      section
        == LayersPanelSection(
          heading: heading, choice: .overlay, category: "conditions", rows: rows,
          categories: categories))
    #expect(
      section
        != LayersPanelSection(
          heading: heading, choice: .enrichment, category: "conditions", rows: rows,
          categories: categories))
    #expect(
      section
        != LayersPanelSection(
          heading: heading, choice: .overlay, category: nil, rows: rows, categories: categories))
    #expect(
      section
        != LayersPanelSection(
          heading: heading, choice: .overlay, category: "conditions", rows: [],
          categories: categories))
    #expect(
      section
        != LayersPanelSection(
          heading: heading, choice: .overlay, category: "conditions", rows: rows),
      "a section offering no category is another")
    #expect(
      section
        != LayersPanelSection(
          heading: heading, choice: .overlay, category: "conditions", rows: rows,
          categories: [LayersPanelCategory(slug: "conditions", name: "Conditions\u{301}")]),
      "a section offering another category is another")
    #expect(
      LayersPanelSection(
        heading: LayersPanelHeading(word: "layers.time"), choice: .time, category: nil, rows: []
      ).categories.isEmpty)
  }
}
