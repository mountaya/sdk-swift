import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("SearchConfiguration")
struct SearchConfigurationTests {
  @Test("a configuration asks every branch in the section order, and nothing else, by default")
  func defaults() {
    let configuration = SearchConfiguration()

    #expect(configuration.fetch == nil)
    #expect(configuration.language == nil)
    #expect(configuration.limit == nil)
    #expect(configuration.targets == searchSectionOrder)
    #expect(configuration.wording.units == nil)
    #expect(configuration.onError == nil)
  }

  @Test(
    "the section order is the itineraries, places, ways, points of interest, zones, collections")
  func sectionOrder() {
    #expect(
      searchSectionOrder.map(\.rawValue)
        == ["ITINERARIES", "PLACES", "WAYS", "POIS", "ZONES", "COLLECTIONS"])
  }
}
