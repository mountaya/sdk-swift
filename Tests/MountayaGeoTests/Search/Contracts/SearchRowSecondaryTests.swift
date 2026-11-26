import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("SearchRowSecondary")
struct SearchRowSecondaryTests {
  @Test("two second lines are equal where they hold the same values")
  func equality() {
    #expect(
      SearchRowSecondary.metric(distance: .nan, ascent: nil) == .metric(distance: .nan, ascent: nil)
    )
    #expect(SearchRowSecondary.metric(distance: 0, ascent: 1) != .metric(distance: -0.0, ascent: 1))
    #expect(SearchRowSecondary.count(itineraries: 7) == .count(itineraries: 7))
    #expect(SearchRowSecondary.text("7") != .count(itineraries: 7))
    #expect(
      SearchRowSecondary.metric(distance: .nan, ascent: 3).hashValue
        == SearchRowSecondary.metric(distance: .nan, ascent: 3).hashValue)
  }

  @Test("two sentences are told apart by their scalars")
  func scalars() {
    #expect(SearchRowSecondary.text("\u{E9}") != .text("e\u{301}"))
    #expect(SearchRowSecondary.text("\u{E9}") == .text("\u{E9}"))
  }
}
