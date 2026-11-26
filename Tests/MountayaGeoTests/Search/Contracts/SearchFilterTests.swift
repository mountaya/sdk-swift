import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("SearchFilter")
struct SearchFilterTests {
  @Test("every target is under all, and under exactly one narrowing filter")
  func targets() {
    let narrowing = SearchFilter.allCases.filter { $0 != .all }
    for target in SearchFilter.all.targets {
      #expect(narrowing.filter { $0.targets.contains(target) }.count == 1, "\(target.rawValue)")
    }
    #expect(SearchFilter.allCases.map(\.id) == ["all", "itineraries", "places", "zones"])
    #expect(SearchFilter(rawValue: "places") == .places)
  }
}
