import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("SearchSectionState")
struct SearchSectionStateTests {
  struct Refused: Error {}

  @Test("a state says whether it loads, whether it settled, and why it failed")
  func readings() {
    #expect(SearchSectionState.loading.isLoading)
    #expect(!SearchSectionState.loading.isSettled)
    #expect(SearchSectionState.loading.failure == nil)
    #expect(SearchSectionState.settled.isSettled)
    #expect(!SearchSectionState.settled.isLoading)
    #expect(SearchSectionState.settled.failure == nil)
    let failed = SearchSectionState.failed(Refused())
    #expect(!failed.isLoading && !failed.isSettled)
    #expect(failed.failure is Refused)
  }
}
