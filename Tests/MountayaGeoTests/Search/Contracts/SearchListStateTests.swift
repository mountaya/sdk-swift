import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("SearchListState")
struct SearchListStateTests {
  @Test("a list state holds its rows, its failed sections, its flags and its status")
  func members() {
    let state = SearchListState(
      rows: [],
      failed: [SearchSection(id: .zones, state: .failed(SearchBranchError(target: .zones)))],
      isNothingFound: false, hasFallbackNote: true, status: .error)

    #expect(state.rows.isEmpty)
    #expect(state.failed.map(\.id) == [.zones])
    #expect(!state.isNothingFound)
    #expect(state.hasFallbackNote)
    #expect(state.status == .error)
  }
}
