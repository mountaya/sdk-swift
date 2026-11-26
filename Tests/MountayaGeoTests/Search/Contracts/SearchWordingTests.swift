import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("SearchWording")
struct SearchWordingTests {
  /// Swift compares no two functions, so a wording is not `Equatable`; its members are read.
  @Test("the default words nothing, and a wording holds the units and the words it is given")
  func members() {
    #expect(SearchWording().resolveLabel(.highway("path")) == nil)
    #expect(SearchWording().units == nil)
    let french = SearchWording(units: UnitPreferences(language: "fr")) { _ in "mot" }
    #expect(french.units == UnitPreferences(language: "fr"))
    #expect(french.resolveLabel(.highway("path")) == "mot")
  }
}
