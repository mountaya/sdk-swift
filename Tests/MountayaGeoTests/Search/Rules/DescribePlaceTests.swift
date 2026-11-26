import Foundation
import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("describePlace")
struct DescribePlaceTests {
  private let english = SearchWording()

  @Test("a place states its category, region and country")
  func place() {
    #expect(describePlace(SearchEntities.place(), wording: english) == "Populated place")
    #expect(
      describePlace(
        SearchEntities.place(
          region: "Auvergne-Rh\u{F4}ne-Alpes", country: "FR", countryName: "France"),
        wording: english)
        == "Populated place \u{B7} Auvergne-Rh\u{F4}ne-Alpes \u{B7} France \u{1F1EB}\u{1F1F7}")
    #expect(
      describePlace(
        SearchEntities.place(name: "France", category: "COUNTRY", region: "x"), wording: english)
        == "Country")
    #expect(
      describePlace(
        SearchEntities.place(name: "Home", category: "ADDRESS", label: "1 Rue Royale"),
        wording: english) == "1 Rue Royale")
  }

  @Test("a POI states its elevation where it is meaningful, else its distance")
  func poi() {
    #expect(
      describePoi(SearchEntities.poi(elevation: 3835, distance: 1200), wording: english)
        == "Hut \u{B7} 3835 m")
    #expect(
      describePoi(SearchEntities.poi(elevation: 12, distance: 1200), wording: english)
        == "Hut \u{B7} 1.2 km")
    #expect(
      describePoi(
        SearchEntities.poi(distance: 3, city: "Chamonix", region: "Haute-Savoie"), wording: english)
        == "Hut \u{B7} Chamonix")
    #expect(
      describePoi(SearchEntities.poi(distance: 1200), wording: SearchWording { _ in "Refuge" })
        == "Refuge \u{B7} 1.2 km")
  }

  @Test("a distance rounds to ten meters, then to a tenth of a kilometre")
  func distance() {
    #expect(distanceToken(850, units: nil) == "850 m")
    #expect(distanceToken(994, units: nil) == "990 m")
    #expect(distanceToken(996, units: nil) == "1.0 km")
    #expect(distanceToken(995, units: nil) == "1.0 km")
    #expect(distanceToken(5, units: nil) == "10 m")
    #expect(distanceToken(4.9, units: nil) == "")
    // Half away from zero on the decimal value: 1,150 m is 1.15 km, which reads 1.2.
    #expect(distanceToken(1150, units: nil) == "1.2 km")
    // A figure past the range of a 64-bit integer is held at its end, never a trap.
    #expect(distanceToken(.infinity, units: nil) == "922337203685477580.7 km")
  }

  @Test("a distance in the reader's units is written in their system and digits")
  func readersUnits() {
    let french = UnitPreferences(language: "fr")
    #expect(
      distanceToken(850, units: french)
        == unitPatterns("fr").meter.replacingOccurrences(of: "{0}", with: "850"))
    #expect(
      distanceToken(1200, units: french)
        == unitPatterns("fr").kilometer.replacingOccurrences(of: "{0}", with: "1,2"))
    // A figure stated to one decimal keeps its zero.
    #expect(
      distanceToken(1000, units: french)
        == unitPatterns("fr").kilometer.replacingOccurrences(of: "{0}", with: "1,0"))
    let imperial = UnitPreferences(language: "en", length: .imperial)
    // 300 m is 984.25 ft, which reads 980.
    #expect(distanceToken(300, units: imperial) == "980 ft")
    #expect(distanceToken(305, units: imperial) == "0.2 mi")
    #expect(elevationToken(1531, units: UnitPreferences(language: "en")) == "1,531 m")
  }

  @Test("a way states its tag, its grade or surface, and where it is")
  func way() {
    #expect(describeWay(SearchEntities.way(), wording: english) == "Path")
    #expect(
      describeWay(
        SearchEntities.way(sacScale: "mountain_hiking", surface: "gravel"), wording: english)
        == "Path \u{B7} Mountain hiking")
    #expect(
      describeWay(SearchEntities.way(sacScale: "hiking", surface: "gravel"), wording: english)
        == "Path \u{B7} gravel surface")
    #expect(
      describeWay(
        SearchEntities.way(surface: "gravel"),
        wording: SearchWording { label in
          if case .surface = label { return "Schotter" }
          return nil
        }) == "Path \u{B7} Schotter")
  }

  @Test("a whole figure is held within a 64-bit integer, NaN read as zero")
  func wholeFigures() {
    #expect(wholeFigure(3835) == 3835)
    #expect(wholeFigure(.nan) == 0)
    #expect(wholeFigure(.infinity) == .max)
    #expect(wholeFigure(-.infinity) == .min)
    #expect(wholeFigure(-0x1p63) == .min)
  }

  @Test("a published line reads in English titles and metric figures where it is given no wording")
  func published() {
    #expect(
      describePlace(SearchEntities.place(name: "Lyon", country: "FR", countryName: "France"))
        == "Populated place \u{B7} France \u{1F1EB}\u{1F1F7}", "a place with no region")
    #expect(
      describePlace(SearchEntities.place(name: "Annecy", region: "annecy"))
        == "Populated place", "a region that repeats the title")
    #expect(
      describePlace(
        SearchEntities.place(name: "", region: "Valais", country: "CH", countryName: "Suisse"))
        == "Valais \u{B7} Suisse \u{1F1E8}\u{1F1ED}", "an unnamed place titled by what it is")
    #expect(
      describePlace(
        SearchEntities.place(
          name: "12 Rue du Lac", category: "ADDRESS", label: "12 Rue du Lac, Annecy",
          country: "FR", countryName: "France"))
        == "12 Rue du Lac, Annecy \u{B7} France \u{1F1EB}\u{1F1F7}")
    #expect(describePoi(SearchEntities.poi(name: "", distance: 200)) == "200 m")
    #expect(describePoi(SearchEntities.poi(name: "Hut", distance: 200)) == "200 m")
    #expect(describePoi(SearchEntities.poi(elevation: 100, distance: 350)) == "Hut \u{B7} 100 m")
    #expect(describePoi(SearchEntities.poi(elevation: 99, distance: 350)) == "Hut \u{B7} 350 m")
    #expect(describeWay(SearchEntities.way(name: "", surface: "gravel")) == "gravel surface")
  }

  @Test("a figure in the reader's imperial units reads in miles, feet to the nearest ten, or feet")
  func imperial() {
    let imperial = SearchWording(
      units: UnitPreferences(language: "en", length: .imperial))
    #expect(
      describePoi(SearchEntities.poi(name: "P1", distance: 4200), wording: imperial)
        == "Hut \u{B7} 2.6 mi")
    #expect(
      describePoi(SearchEntities.poi(name: "P1", distance: 137), wording: imperial)
        == "Hut \u{B7} 450 ft")
    #expect(
      describePoi(SearchEntities.poi(elevation: 2483), wording: imperial) == "Hut \u{B7} 8,146 ft")
  }
}
