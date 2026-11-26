import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("searchListState")
struct SearchListStateRuleTests {
  private static func section(
    _ id: DataSchema.SearchTarget, state: SearchSectionState, titles: [String] = []
  ) -> SearchSection {
    SearchSection(
      id: id, state: state,
      rows: titles.map { title in
        SearchRow(
          id: "\(id.rawValue):\(title)", title: title, matched: [], secondary: nil,
          activities: [], payload: .itinerary(itineraryId: title, bounds: nil, start: nil))
      })
  }

  private static func snapshot(
    _ sections: [SearchSection], searching: Bool = false, settled: Bool = true,
    fallback: Bool = false
  ) -> SearchSnapshot {
    SearchSnapshot(
      query: "chamonix", isSearching: searching, isSettled: settled, hasFallenBack: fallback,
      sections: sections)
  }

  private static let failed = SearchSectionState.failed(SearchBranchError(target: .zones))

  @Test("a failure under the filter is announced, and one outside it is not")
  func failures() {
    let round = Self.snapshot([
      Self.section(.itineraries, state: .settled), Self.section(.places, state: .settled),
      Self.section(.zones, state: Self.failed),
    ])
    let all = searchListState(round, filter: .all)
    #expect(all.failed.map(\.id) == [.zones])
    #expect(all.status == .error)
    #expect(!all.isNothingFound)
    let places = searchListState(round, filter: .places)
    #expect(places.failed.isEmpty)
    #expect(places.isNothingFound)
    #expect(places.status == .emptyTitle)
  }

  @Test("a settled round counts the rows its filter shows, in the order they render")
  func counted() {
    let round = Self.snapshot([
      Self.section(.itineraries, state: .settled, titles: ["Tour du Mont Blanc", "Haute Route"]),
      Self.section(.places, state: .settled, titles: ["Chamonix"]),
      Self.section(.collections, state: .settled, titles: ["Alpine Classics"]),
    ])
    #expect(
      searchListState(round, filter: .all).rows.map(\.title)
        == ["Tour du Mont Blanc", "Haute Route", "Chamonix", "Alpine Classics"])
    let itineraries = searchListState(round, filter: .itineraries)
    #expect(
      itineraries.rows.map(\.title) == ["Tour du Mont Blanc", "Haute Route", "Alpine Classics"])
    #expect(itineraries.status == .resultCount(3))
  }

  @Test("a round in flight announces nothing but a failure, and shows the rows it keeps")
  func inFlight() {
    let loading = Self.snapshot(
      [Self.section(.itineraries, state: .loading), Self.section(.zones, state: .loading)],
      searching: true,
      settled: false)
    #expect(searchListState(loading, filter: .all).status == nil)
    #expect(!searchListState(loading, filter: .all).isNothingFound)
    let kept = Self.snapshot(
      [
        Self.section(.itineraries, state: .settled, titles: ["Lac Blanc"]),
        Self.section(.zones, state: .settled),
      ],
      searching: true, settled: false)
    #expect(searchListState(kept, filter: .all).rows.map(\.title) == ["Lac Blanc"])
    #expect(searchListState(kept, filter: .all).status == nil)
    let failing = Self.snapshot(
      [Self.section(.itineraries, state: .loading), Self.section(.zones, state: Self.failed)],
      searching: true,
      settled: false)
    #expect(searchListState(failing, filter: .all).status == .error)
  }

  @Test("nothing is found only once a round settled, and a fall back is noted either way")
  func nothingFound() {
    let asked = Self.snapshot(
      [Self.section(.itineraries, state: .settled), Self.section(.zones, state: .settled)],
      settled: false)
    #expect(!searchListState(asked, filter: .all).isNothingFound, "a search that asked nothing")
    #expect(searchListState(asked, filter: .all).status == nil)
    let fellBack = Self.snapshot(
      [Self.section(.itineraries, state: .settled), Self.section(.zones, state: .settled)],
      fallback: true)
    #expect(searchListState(fellBack, filter: .all).hasFallbackNote)
    #expect(searchListState(fellBack, filter: .all).isNothingFound)
    let found = Self.snapshot(
      [
        Self.section(.itineraries, state: .settled, titles: ["Aiguillette"]),
        Self.section(.zones, state: .settled),
      ],
      fallback: true)
    #expect(searchListState(found, filter: .all).hasFallbackNote)
    #expect(searchListState(found, filter: .all).status == .resultCount(1))
    let none = Self.snapshot([
      Self.section(.itineraries, state: .settled, titles: ["Tour du Mont Blanc"]),
      Self.section(.places, state: .settled, titles: ["Chamonix"]),
    ])
    #expect(searchListState(none, filter: .zones).isNothingFound, "a filter showing none")
  }

  @Test("a section is shown by its branch's scalars")
  func scalars() {
    let round = Self.snapshot([
      Self.section(DataSchema.SearchTarget(rawValue: "ZON\u{C9}S"), state: .settled, titles: ["x"])
    ])
    #expect(searchListState(round, filter: .all).rows.isEmpty)
  }
}
