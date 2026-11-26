import MountayaClient
import Foundation
import Testing

@testable import MountayaGeo

@Suite("readoutRows")
struct ReadoutRowsTests {
  private let point = [6.8652, 45.9237]

  @Test("at the detail zoom the point of interest, the terrain and the zone stand")
  func detail() {
    var facts = ReadoutFacts(position: point, zoom: 14)
    facts.poi = ReadoutFacts.POI(name: "Refuge", category: "alpine_hut")
    facts.terrain = TerrainReading(elevation: 1834.6, slope: 32.4, aspect: 135.2)
    facts.zone = ReadoutFacts.Zone(
      name: "Couloir", description: "", level: "warning", startAt: 1_773_475_200, endAt: nil)
    let rows = readoutRows(facts)
    #expect(rows.count == 4)
    #expect(rows[0] == .poi(name: "Refuge", category: .hut, label: "Hut"))
    #expect(
      rows[1]
        == .terrain([
          .altitude(1834.6), .slope(32.4, color: "#b71c1c"),
          .aspect(135.2, cardinal: .southEast),
        ]))
    #expect(rows[2] == .coordinates(text: "45.9237°N 6.8652°E", copy: "45.92370, 6.86520"))
    guard case .zone(_, let description, _, let levelWord, let color, let window) = rows[3] else {
      Issue.record("no zone row")
      return
    }
    #expect(description == nil && levelWord == "readout.zoneLevels.warning" && color == "#f59f00")
    #expect(window?.word == "readout.zoneWindowFrom")
  }

  @Test("a level the table does not name keeps its spelling, in the colour of info")
  func unnamedLevel() {
    var facts = ReadoutFacts(position: point, zoom: 14)
    facts.zone = ReadoutFacts.Zone(
      name: "Col", description: "", level: RestSchema.ZoneLevel(rawValue: "Danger"),
      startAt: nil, endAt: nil)
    guard case .zone(_, _, let level, let levelWord, let color, _) = readoutRows(facts).last else {
      Issue.record("no zone row")
      return
    }
    #expect(level.rawValue == "Danger" && levelWord == nil && color == "#1c7ed6")
    facts.zone?.level = .danger
    guard case .zone(_, _, _, let word, let red, _) = readoutRows(facts).last else {
      Issue.record("no zone row")
      return
    }
    #expect(word == "readout.zoneLevels.danger" && red == "#f03e3e")
  }

  @Test("below the detail zoom the band and the coordinates stay, with a note to zoom in")
  func below() {
    var facts = ReadoutFacts(position: point, zoom: 12.99)
    facts.poi = ReadoutFacts.POI(name: "Refuge", category: "alpine_hut")
    facts.overlay = ReadoutFacts.Overlay(slug: "snowdepth", name: "Snow depth", vector: true)
    facts.band = (0.2, 0.5)
    let rows = readoutRows(facts)
    #expect(
      rows.first
        == .band(
          overlay: "Snow depth", measure: .snowfall, pace: nil, values: [20, 50],
          word: "readout.overlayRange", time: nil))
    #expect(rows.last == .zoomIn)
  }

  @Test("a vector overlay with no band states its moment alone, a raster one none")
  func moment() {
    let instant = Date(timeIntervalSince1970: 1_773_480_360)
    var facts = ReadoutFacts(position: point, zoom: 14, instant: instant)
    facts.overlay = ReadoutFacts.Overlay(slug: "wind", name: "Wind", vector: true)
    #expect(readoutRows(facts).first == .instant(instant))
    facts.overlay = ReadoutFacts.Overlay(slug: "steepness", name: "Slope", vector: false)
    #expect(readoutRows(facts).count == 1)
  }

  @Test("a copied coordinate is rounded half away from zero, and one at zero has no sign")
  func copied() {
    #expect(copiedPair([-0.1276, 51.5072]) == "51.50720, -0.12760")
    #expect(copiedPair([-1e-06, -4e-06]) == "0.00000, 0.00000")
    #expect(copiedPair([0.015625, 0]) == "0.00000, 0.01563")
  }
}
