import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("SearchLabel")
struct SearchLabelTests {
  @Test("two labels are equal where they name one value of one kind")
  func equality() {
    #expect(SearchLabel.poiCategory(.hut) == .poiCategory(DataSchema.POICategory(rawValue: "HUT")))
    #expect(SearchLabel.highway("path") != .surface("path"))
    #expect(SearchLabel.sacScale("alpine_hiking") == .sacScale("alpine_hiking"))
  }

  @Test(
    "two labels are told apart by the scalars of the value they name, and equal ones hash alike")
  func scalars() {
    #expect(SearchLabel.surface("\u{E9}") != .surface("e\u{301}"))
    #expect(SearchLabel.highway("\u{E9}") != .highway("e\u{301}"))
    #expect(SearchLabel.sacScale("\u{E9}") != .sacScale("e\u{301}"))
    #expect(
      SearchLabel.poiCategory(DataSchema.POICategory(rawValue: "\u{E9}"))
        != .poiCategory(DataSchema.POICategory(rawValue: "e\u{301}")))
    #expect(
      SearchLabel.placeCategory(DataSchema.PlaceCategory(rawValue: "\u{E9}"))
        != .placeCategory(DataSchema.PlaceCategory(rawValue: "e\u{301}")))
    #expect(SearchLabel.placeCategory(.country) == .placeCategory(.country))
    #expect(
      SearchLabel.placeCategory(.country).hashValue == SearchLabel.placeCategory(.country).hashValue
    )
    #expect(SearchLabel.highway("path").hashValue == SearchLabel.highway("path").hashValue)
  }
}
