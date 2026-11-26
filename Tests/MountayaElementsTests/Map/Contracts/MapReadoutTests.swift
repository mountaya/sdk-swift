import Foundation
import MountayaClient
import MountayaGeo
import Testing

@testable import MountayaElements

@Suite("MapReadout")
struct MapReadoutTests {
  @Test("a readout stands at the place its facts were read at")
  func position() {
    let readout = MapReadout(
      number: 1, point: [10, 20], facts: ReadoutFacts(position: [6.8652, 45.9237], zoom: 14))
    #expect(readout.position == [6.8652, 45.9237])
    #expect(readout.facts.terrain == nil)
  }

  @Test("the classic overlay is named in the language of the readout's words")
  func overlayName() throws {
    var facts = ReadoutFacts(position: [6.8652, 45.9237], zoom: 14)
    facts.overlay = ReadoutFacts.Overlay(slug: "wind", name: "Wind", vector: true)
    let names = try JSONDecoder().decode(
      TileSchema.Locales.self,
      from: Data(#"{"en": {"name": "Wind"}, "fr": {"name": "Vent"}}"#.utf8))
    let readout = MapReadout(number: 1, point: [10, 20], facts: facts, overlayNames: names)
    #expect(readout.facts(in: .fr).overlay?.name == "Vent")
    #expect(readout.facts(in: .de).overlay?.name == "Wind", "a language with none reads English")
    #expect(
      MapReadout(number: 2, point: [0, 0], facts: facts).facts(in: .fr).overlay?.name == "Wind")
  }
}
