import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("SearchQueryChange")
struct SearchQueryChangeTests {
  @Test("two rounds are equal where they ask the same query")
  func equality() {
    #expect(SearchQueryChange.ask(query: "mont") == .ask(query: "mont"))
    #expect(
      SearchQueryChange.ask(query: "mont").hashValue
        == SearchQueryChange.ask(query: "mont").hashValue)
    #expect(SearchQueryChange.ask(query: "mont") != .ask(query: "Mont"))
    #expect(SearchQueryChange.clear != .unchanged)
  }

  @Test("two rounds are told apart by the scalars of their queries")
  func scalars() {
    #expect(SearchQueryChange.ask(query: "\u{E9}") != .ask(query: "e\u{301}"))
    #expect(SearchQueryChange.ask(query: "\u{E9}") == .ask(query: "\u{E9}"))
    #expect(SearchQueryChange.clear == .clear)
    #expect(SearchQueryChange.unchanged.hashValue == SearchQueryChange.unchanged.hashValue)
    #expect(SearchQueryChange.ask(query: "") != .clear)
  }
}
