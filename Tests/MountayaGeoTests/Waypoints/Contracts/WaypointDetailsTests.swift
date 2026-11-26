import Foundation
import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("WaypointDetails")
struct WaypointDetailsTests {
  private func details(
    cutoffAt: Date? = Date(timeIntervalSince1970: 1_782_885_600), phone: String? = "+33 4 50",
    caption: String? = "The hut", format: RestSchema.WaypointPropertyFormat? = nil
  ) throws -> WaypointDetails {
    WaypointDetails(
      amenities: [.water],
      description: "A bench by the fountain.",
      timing: WaypointDetails.Timing(cutoffAt: cutoffAt, stopDuration: 900),
      contact: WaypointDetails.Contact(phone: phone, website: "https://refuge.example"),
      media: WaypointDetails.Media(
        photos: [
          WaypointDetails.Photo(url: "https://refuge.example/hut.jpg", caption: caption)
        ],
        links: [WaypointDetails.Link(label: "Topo", url: "https://refuge.example/topo")]),
      properties: [
        WaypointDetails.Property(key: "beds", label: "Beds", value: "12", format: format)
      ])
  }

  @Test("two details are equal when every member is, and hash alike")
  func equality() throws {
    #expect(try details() == details())
    #expect(try details().hashValue == details().hashValue)
    #expect(try details(phone: nil) != details())
    #expect(try details(caption: nil) != details())
    #expect(try details(format: .number) != details())
    #expect(try details(cutoffAt: nil) != details())
  }

  /// A `Date` is a number of seconds, compared as every number of the geo layer is.
  @Test("a cut-off is compared as the same number of seconds")
  func cutoffBySameNumber() throws {
    let nan = Date(timeIntervalSinceReferenceDate: .nan)

    #expect(try details(cutoffAt: nan) == details(cutoffAt: nan))
    #expect(try details(cutoffAt: nan).hashValue == details(cutoffAt: nan).hashValue)
    #expect(
      try details(cutoffAt: Date(timeIntervalSinceReferenceDate: 0))
        != details(cutoffAt: Date(timeIntervalSinceReferenceDate: -0.0)))
  }

  @Test("a text is compared scalar for scalar")
  func textsByScalars() throws {
    #expect(try details(phone: "caf\u{E9}") != details(phone: "cafe\u{301}"))
    #expect(try details(caption: "caf\u{E9}") != details(caption: "cafe\u{301}"))
    #expect(
      WaypointDetails.Link(label: "Topo", url: "https://a.example/caf\u{E9}")
        != WaypointDetails.Link(label: "Topo", url: "https://a.example/cafe\u{301}"))
    #expect(
      WaypointDetails.Contact(website: "refuge dot example").website == "refuge dot example")
  }

  @Test("details built with nothing hold nothing")
  func defaults() {
    let empty = WaypointDetails()

    #expect(empty.amenities == nil && empty.description == nil && empty.timing == nil)
    #expect(empty.contact == nil && empty.media == nil && empty.properties == nil)
    #expect(WaypointDetails.Timing() == WaypointDetails.Timing(cutoffAt: nil, stopDuration: nil))
    #expect(WaypointDetails.Media().photos == nil && WaypointDetails.Media().links == nil)
  }
}
