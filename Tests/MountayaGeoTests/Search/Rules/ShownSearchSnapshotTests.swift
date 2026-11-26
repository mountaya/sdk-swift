import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("shownSearchSnapshot")
struct ShownSearchSnapshotTests {
  @Test("a list shows the search's answer where it names the query typed, trimmed")
  func answered() {
    let answer = SearchSnapshot(query: "chamonix", isSettled: true)
    let stand = SearchSnapshot(query: "zermatt", isSearching: true)

    #expect(shownSearchSnapshot(answer, query: " chamonix ", unanswered: stand).isSettled)
    #expect(shownSearchSnapshot(answer, query: "zermatt", unanswered: stand).query == "zermatt")
    #expect(
      shownSearchSnapshot(answer, query: "Chamonix", unanswered: stand).query == "zermatt",
      "letter case is part of the query")
    #expect(
      shownSearchSnapshot(
        SearchSnapshot(query: "caf\u{E9}"), query: "cafe\u{301}", unanswered: stand
      ).query == "zermatt", "a query is compared by its scalars")
  }
}
