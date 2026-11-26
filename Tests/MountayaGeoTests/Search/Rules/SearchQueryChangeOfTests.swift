import Testing

@testable import MountayaGeo

@Suite("searchQueryChangeOf")
struct SearchQueryChangeOfTests {
  @Test("the trimmed query is the round's identity")
  func identity() {
    #expect(searchQueryChangeOf(settled: "", typed: " mont ") == .ask(query: "mont"))
    #expect(searchQueryChangeOf(settled: "mont", typed: " mont ") == .unchanged)
    #expect(searchQueryChangeOf(settled: "mont", typed: "mont") == .unchanged)
  }

  @Test("a query that trims to nothing clears the search and asks nothing")
  func clear() {
    #expect(searchQueryChangeOf(settled: "mont", typed: "") == .clear)
    #expect(searchQueryChangeOf(settled: "mont", typed: "\u{3000}\t") == .clear)
    // An empty box before any query, or after a cleared one, asks nothing at all.
    #expect(searchQueryChangeOf(settled: "", typed: "  ") == .unchanged)
  }

  @Test("letter case is part of the query")
  func letterCase() {
    #expect(
      searchQueryChangeOf(settled: "mont blanc", typed: "Mont Blanc") == .ask(query: "Mont Blanc"))
  }

  /// Only the ECMAScript set is trimmed: a zero width space is part of the query, and a query is
  /// compared as it is written, scalar for scalar.
  @Test("the white space trimmed is the one set")
  func whiteSpace() {
    #expect(
      searchQueryChangeOf(settled: "mont", typed: "\u{200B}mont") == .ask(query: "\u{200B}mont"))
    #expect(
      searchQueryChangeOf(settled: "Pr\u{E9}", typed: "Pre\u{301}") == .ask(query: "Pre\u{301}"))
  }
}
