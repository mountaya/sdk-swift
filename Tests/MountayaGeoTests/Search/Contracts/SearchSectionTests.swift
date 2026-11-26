import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("SearchSection")
struct SearchSectionTests {
  @Test("a section is identified by its branch, and holds no row unless handed some")
  func members() {
    let section = SearchSection(id: .zones, state: .settled)

    #expect(section.id == .zones)
    #expect(section.rows.isEmpty)
    #expect(section.state.isSettled)
    let row = SearchRow(
      id: "zone:z", title: "Couloir", matched: [], secondary: nil, activities: [],
      payload: .zone(zoneId: "z", point: nil, bounds: nil))
    #expect(SearchSection(id: .zones, state: .settled, rows: [row]).rows == [row])
  }
}
