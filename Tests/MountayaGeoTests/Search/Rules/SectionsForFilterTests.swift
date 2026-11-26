import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("sectionsForFilter")
struct SectionsForFilterTests {
  private let sections: [DataSchema.SearchTarget] = [
    .places, .pois, .ways, .itineraries, .collections, .zones,
  ]

  @Test("a filter shows its sections in the order given")
  func order() {
    #expect(sectionsForFilter(sections, filter: .all) == sections)
    #expect(sectionsForFilter(sections, filter: .itineraries) == [.itineraries, .collections])
    #expect(sectionsForFilter(sections, filter: .places) == [.places, .pois, .ways])
    #expect(sectionsForFilter(sections.reversed(), filter: .zones) == [.zones])
    #expect(
      sectionsForFilter(sections.reversed(), filter: .itineraries) == [.collections, .itineraries])
  }

  @Test("a target this build does not know is shown by no filter")
  func unknown() {
    #expect(sectionsForFilter([DataSchema.SearchTarget(rawValue: "PEAKS")], filter: .all).isEmpty)
  }
}
