import Foundation
import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("waypointCard")
struct WaypointCardOfTests {
  private let english = UnitPreferences(language: "en")

  @Test("every contact line in its order, a phone and an email with their scheme")
  func contact() {
    let card = waypointCard(
      WaypointDetails(
        contact: WaypointDetails.Contact(
          address: "Val Veny", bookingUrl: "https://refuge.example/book",
          email: "refuge@example.com",
          openingHours: "June to September", phone: "+39 0165", website: "https://refuge.example")),
      scope: .standard, units: english)
    #expect(
      card.contact.map(\.label) == [
        "Opening hours", "Address", "Phone", "Email", "Website", "Booking page",
      ])
    #expect(
      card.contact.map(\.href) == [
        nil, nil, "tel:+39 0165", "mailto:refuge@example.com", "https://refuge.example",
        "https://refuge.example/book",
      ])
    #expect(card.contact.map(\.isExternal) == [false, false, false, false, true, true])
  }

  @Test("a website or booking page that is no web address is stated as text")
  func notAddress() {
    let card = waypointCard(
      WaypointDetails(
        contact: WaypointDetails.Contact(
          bookingUrl: "javascript:alert(1)", website: "refuge dot example")),
      scope: .standard, units: english)
    #expect(card.contact.map(\.value) == ["refuge dot example", "javascript:alert(1)"])
    #expect(card.contact.allSatisfy { $0.href == nil && !$0.isExternal })
  }

  @Test("a cut-off only through the caller's formatter, then the stop, one of no minute none")
  func timing() {
    let details = WaypointDetails(
      timing: WaypointDetails.Timing(cutoffAt: Date(timeIntervalSince1970: 0), stopDuration: 1_200))
    #expect(
      waypointCard(details, scope: .standard, units: english) { _ in "10:30" }.timing
        == [
          WaypointCardFacts.Line(label: "Cut-off time", value: "10:30"),
          WaypointCardFacts.Line(label: "Planned stop", value: "20m"),
        ])
    #expect(
      waypointCard(details, scope: .standard, units: english).timing.map(\.label) == [
        "Planned stop"
      ])
    let brief = WaypointDetails(timing: WaypointDetails.Timing(stopDuration: 20))
    #expect(waypointCard(brief, scope: .standard, units: english).timing.isEmpty)
  }

  @Test("services by name, one with none by its value, and fields by their format")
  func servicesAndFields() {
    let card = waypointCard(
      WaypointDetails(
        amenities: ["water", "sauna"],
        properties: [
          WaypointDetails.Property(
            key: "page", label: "Page", value: " https://a.example ", format: "url")
        ]),
      scope: .standard, units: english)
    #expect(card.services.map(\.name) == ["Water", "sauna"])
    #expect(
      card.fields == [
        WaypointField(
          key: "page", label: "Page", value: " https://a.example ", href: "https://a.example")
      ])
  }

  @Test("links anchored only at a web address, photos left out at any other, and the headline")
  func mediaAndHeadline() {
    let card = waypointCard(
      WaypointDetails(
        amenities: ["water"],
        timing: WaypointDetails.Timing(stopDuration: 900),
        media: WaypointDetails.Media(
          photos: [
            WaypointDetails.Photo(url: " https://a.example/hut.jpg"),
            WaypointDetails.Photo(url: "data:x"),
          ],
          links: [
            WaypointDetails.Link(label: "Topo", url: " https://a.example/topo "),
            WaypointDetails.Link(label: "Notes", url: "ask"),
          ])),
      scope: .standard, units: english)
    #expect(card.links.map(\.href) == ["https://a.example/topo", nil])
    #expect(card.photos.map(\.url) == ["https://a.example/hut.jpg"])
    #expect(card.headline == "Services · 15m stop")
    #expect(!card.isEmpty)
    let described = waypointCard(
      WaypointDetails(description: "  Closed in winter. "), scope: .standard, units: english)
    #expect(described.headline == "Closed in winter." && described.isEmpty)
  }

  @Test("a place that records nothing states nothing")
  func nothing() {
    let card = waypointCard(nil, scope: .standard, units: english)
    #expect(
      card.services.isEmpty && card.timing.isEmpty && card.contact.isEmpty && card.fields.isEmpty)
    #expect(card.headline == nil && card.isEmpty)
  }
}
