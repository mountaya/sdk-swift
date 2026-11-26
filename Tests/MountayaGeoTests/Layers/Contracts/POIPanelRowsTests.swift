import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("POIPanelRows")
struct POIPanelRowsTests {
  @Test("a picker's offer holds its rows in order and its master row")
  func members() {
    let rows = [POIPanelRow(id: "parking", label: "parking", keys: ["parking"], isVisible: false)]
    let offer = POIPanelRows(rows: rows, isAnyVisible: false)

    #expect(offer.rows == rows)
    #expect(!offer.isAnyVisible)
    #expect(offer != POIPanelRows(rows: [], isAnyVisible: false))
  }
}
