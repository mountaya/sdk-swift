import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("amenityName")
struct AmenityNameTests {
  @Test("a service is named by the reader's word, else the English one, else its own value")
  func names() {
    #expect(amenityName("water", in: .standard) == "Water")
    #expect(amenityName("hot-meal", in: .standard) == "Hot meal")
    #expect(amenityName("sauna", in: .standard) == "sauna")
    let french = scopeOf(.standard, stating: ElementsScopeStatement(language: .fr))
    #expect(amenityName("water", in: french) == "Eau")
    let override = scopeOf(
      .standard,
      stating: ElementsScopeStatement(words: .bySection(["amenities": ["water": "Drinking water"]]))
    )
    #expect(amenityName("water", in: override) == "Drinking water")
    #expect(amenityName("food", in: override) == "Food")
  }
}
