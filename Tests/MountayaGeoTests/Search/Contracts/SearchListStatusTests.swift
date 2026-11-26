import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("SearchListStatus")
struct SearchListStatusTests {
  @Test("each status reads the key of its word in the search section")
  func keys() {
    #expect(SearchListStatus.error.key == "error")
    #expect(SearchListStatus.emptyTitle.key == "emptyTitle")
    #expect(SearchListStatus.resultCount(3).key == "resultCount")
    #expect(SearchListStatus.resultCount(3) == .resultCount(3))
    #expect(SearchListStatus.resultCount(3) != .resultCount(1))
    #expect(ElementsScope.standard.word("search.\(SearchListStatus.error.key)") != "search.error")
  }
}
