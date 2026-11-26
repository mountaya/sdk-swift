import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("POIPanelRow")
struct POIPanelRowTests {
  @Test("two rows are equal where every member is, a text by its scalars")
  func equality() {
    let row = POIPanelRow(id: "water", label: "Water", keys: ["spring"], isVisible: true)

    #expect(row.glyph == nil)
    #expect(row == POIPanelRow(id: "water", label: "Water", keys: ["spring"], isVisible: true))
    #expect(row != POIPanelRow(id: "water", label: "Water", keys: ["spring"], isVisible: false))
    #expect(row != POIPanelRow(id: "water", label: "Water", keys: [], isVisible: true))
    #expect(
      row
        != POIPanelRow(id: "water", label: "Water", glyph: "pin", keys: ["spring"], isVisible: true)
    )
  }
}
