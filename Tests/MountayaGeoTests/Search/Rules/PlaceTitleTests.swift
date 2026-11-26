import Testing

@testable import MountayaGeo

@Suite("placeTitle")
struct PlaceTitleTests {
  private let english = SearchWording()

  @Test("an entity is titled by its name, else its category or tag")
  func titled() {
    #expect(placeTitle(SearchEntities.place(), wording: english) == "Annecy")
    #expect(placeTitle(SearchEntities.place(name: ""), wording: english) == "Populated place")
    #expect(poiTitle(SearchEntities.poi(name: "", category: "CAFE"), wording: english) == "Cafe")
    #expect(wayTitle(SearchEntities.way(name: nil, highway: "track"), wording: english) == "Track")
    #expect(poiTitle(SearchEntities.poi(name: nil, category: nil), wording: english) == "")
  }

  @Test("an address with no name is titled by its label")
  func address() {
    #expect(
      placeTitle(
        SearchEntities.place(name: "", category: "ADDRESS", label: "1 Rue Royale"), wording: english
      )
        == "1 Rue Royale")
  }
}
