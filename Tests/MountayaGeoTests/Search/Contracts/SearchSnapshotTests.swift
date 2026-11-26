import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("SearchSnapshot")
struct SearchSnapshotTests {
  @Test("a snapshot names its query, and stands idle, unsettled and unbroadened by default")
  func defaults() {
    let snapshot = SearchSnapshot(query: "chamonix")

    #expect(snapshot.query == "chamonix")
    #expect(!snapshot.isSearching)
    #expect(!snapshot.isSettled)
    #expect(!snapshot.hasFallenBack)
    #expect(snapshot.sections.isEmpty)
    let held = SearchSnapshot(
      query: "", isSearching: true, isSettled: true, hasFallenBack: true,
      sections: [SearchSection(id: .places, state: .loading)])
    #expect(held.isSearching && held.isSettled && held.hasFallenBack)
    #expect(held.sections.map(\.id) == [.places])
  }
}
