import Testing

@testable import MountayaGeo

@Suite("titleCase")
struct TitleCaseTests {
  @Test("a raw value reads with spaces and a capital")
  func titled() {
    #expect(titleCase("demanding_mountain_hiking") == "Demanding mountain hiking")
    #expect(titleCase("path") == "Path")
    #expect(titleCase("") == "")
    // The first unit's full capital: a sharp s is two letters, and a scalar past the basic plane is
    // kept as it is.
    #expect(titleCase("\u{DF}_x") == "SS x")
    #expect(titleCase("\u{1D4B6}x") == "\u{1D4B6}x")
  }

  @Test("a word is the host's, else the fallback")
  func words() {
    let label = SearchLabel.highway("path")
    #expect(wordFor(label, fallback: "Path", wording: SearchWording()) == "Path")
    #expect(
      wordFor(label, fallback: "Path", wording: SearchWording { _ in "Sentier" }) == "Sentier")
    #expect(wordFor(label, fallback: "Path", wording: SearchWording { _ in "" }) == "Path")
  }

  @Test("tokens join with a middle dot, and a token repeating the title is left out")
  func tokens() {
    #expect(joinTokens("Hut", "", nil, "1.2 km") == "Hut \u{B7} 1.2 km")
    #expect(suppressIfMatchesName("Train station", name: "train STATION") == "")
    #expect(suppressIfMatchesName("Hut", name: "Refuge") == "Hut")
    #expect(suppressIfMatchesName(nil, name: "Refuge") == "")
  }

  @Test("a country is its name and its flag")
  func country() {
    #expect(countryToken("fr", name: "France") == "France \u{1F1EB}\u{1F1F7}")
    #expect(countryToken("CH", name: nil) == "\u{1F1E8}\u{1F1ED}")
    #expect(countryToken("C1", name: "Suisse") == "Suisse")
    #expect(countryToken("\u{DF}a", name: nil) == "")
    #expect(countryToken(nil, name: "") == "")
    #expect(countryFlag("FRA") == "")
  }

  @Test("a position is its longitude and latitude, and a position or a box names a place or none")
  func kept() {
    #expect(placeOrNil([6, 45]) == [6, 45])
    #expect(placeOrNil([6, 45, 1200]) == [6, 45])
    #expect(placeOrNil([6, 45, .nan]) == [6, 45])
    #expect(placeOrNil([6]) == nil)
    #expect(placeOrNil([.nan, 45, 1200]) == nil)
    #expect(boxOrNil([6, 45, 7]) == nil)
    #expect(boxOrNil([6, 45, 7, .nan]) == nil)
    #expect(boxOrNil([6, 45, 7, 46]) == [6, 45, 7, 46])
    #expect(textSecondary("x") == .text("x"))
    #expect(textSecondary("") == nil)
    #expect(textSecondary(nil) == nil)
  }
}
