import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("WaypointCardFacts")
struct WaypointCardTests {
  @Test("a line leaves the app only where it says so, and two cards compare by what they state")
  func members() {
    let line = WaypointCardFacts.Line(label: "Phone", value: "+39", href: "tel:+39")
    #expect(!line.isExternal)
    #expect(
      line
        != WaypointCardFacts.Line(label: "Phone", value: "+39", href: "tel:+39", isExternal: true))
    let card = WaypointCardFacts(
      headline: nil, services: [WaypointCardFacts.Service(amenity: "water", name: "Water")],
      timing: [], contact: [line], fields: [],
      links: [
        WaypointCardFacts.MediaLink(
          label: "Topo", url: " https://a.example ", href: "https://a.example")
      ],
      photos: [], isEmpty: false)
    #expect(card == card)
    var other = card
    other.services = [WaypointCardFacts.Service(amenity: "water", name: "Eau")]
    #expect(card != other)
    #expect(
      WaypointCardFacts.MediaLink(label: "Notes", url: "ask", href: nil)
        != WaypointCardFacts.MediaLink(label: "Notes", url: "ask", href: "ask"))
  }
}
