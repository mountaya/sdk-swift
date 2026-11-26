import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("LayersPanelRow")
struct LayersPanelRowTests {
  @Test("two rows are equal where every member is, a text by its scalars")
  func equality() {
    let row = LayersPanelRow(slug: "slopes", label: "Pente", isChecked: true, mark: .tick)

    #expect(row == LayersPanelRow(slug: "slopes", label: "Pente", isChecked: true, mark: .tick))
    #expect(
      row.hashValue
        == LayersPanelRow(slug: "slopes", label: "Pente", isChecked: true, mark: .tick).hashValue)
    #expect(row != LayersPanelRow(slug: "slopes", label: "Pente", isChecked: true, mark: .lock))
    #expect(row != LayersPanelRow(slug: "slopes", label: "Pente", isChecked: false, mark: .tick))
    #expect(
      LayersPanelRow(slug: "a", label: "\u{E9}", isChecked: false, mark: nil)
        != LayersPanelRow(slug: "a", label: "e\u{301}", isChecked: false, mark: nil))
  }
}
