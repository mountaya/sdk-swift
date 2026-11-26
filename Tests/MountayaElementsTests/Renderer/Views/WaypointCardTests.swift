import MountayaClient
import MountayaGeo
import RendererSupport
import SwiftUI
import Testing

@testable import MountayaElements

@Suite("WaypointCard")
@MainActor
struct WaypointCardTests {
  /// hut is a place recording its services, its contact and a link.
  private static let hut = ItineraryPlace(
    id: "hut", lngLat: [6, 45.005], name: "Refuge", glyph: "bed",
    details: WaypointDetails(
      amenities: ["water", "hot-meal"],
      contact: WaypointDetails.Contact(phone: "+33 4 50 00 00 00", website: "javascript:alert(1)"),
      media: WaypointDetails.Media(
        links: [WaypointDetails.Link(label: "Guide", url: "https://refuge.example/guide")])))

  @Test("the card is on the panel's ground, its mark the place's colour, the card's own by default")
  func mark() throws {
    let own = try #require(Controls.drawn(WaypointCard(place: Self.hut)))
    var red = Self.hut
    red.color = "#e03131"
    let coloured = try #require(Controls.drawn(WaypointCard(place: red)))
    let dark = try #require(Controls.drawn(WaypointCard(place: Self.hut), scheme: .dark))
    // Inside the mark's disc, clear of its glyph.
    let face = CGPoint(x: 15, y: 28)

    #expect(Pixels.pixel(own, at: face)?.isNear(Controls.color("#3b82f6")) == true)
    #expect(Pixels.pixel(coloured, at: face)?.isNear(Controls.color("#e03131")) == true)
    let top = CGPoint(x: own.size.width / 2, y: 4)
    #expect(Pixels.pixel(own, at: top)?.isNear(Controls.color("#ffffff")) == true)
    #expect(Pixels.pixel(dark, at: top)?.isNear(Controls.color("#25262b")) == true)
  }

  /// photographed is the hut with two photos at web addresses and one at a script's.
  private static let photographed = ItineraryPlace(
    id: "hut", lngLat: [6, 45.005], name: "Refuge",
    details: WaypointDetails(
      media: WaypointDetails.Media(photos: [
        WaypointDetails.Photo(url: "https://refuge.example/front.jpg", caption: "Front"),
        WaypointDetails.Photo(url: "javascript:alert(1)"),
        WaypointDetails.Photo(url: "https://refuge.example/back.jpg"),
      ])))

  @Test("each photo at a web address is drawn by the app's own view, where it hands one")
  func photoBuilder() throws {
    var handed: Set<String> = []
    let tall = try #require(
      Controls.drawn(
        WaypointCard(place: Self.photographed) { photo in
          let _ = handed.insert(photo.url)
          Color.red.frame(height: 60)
        }))
    let short = try #require(
      Controls.drawn(WaypointCard(place: Self.photographed) { _ in Color.red.frame(height: 10) }))

    #expect(
      handed == ["https://refuge.example/front.jpg", "https://refuge.example/back.jpg"],
      "a photo at any other address is handed to no view")
    // The panel scrolls past 420 points, which both cards keep inside.
    #expect(tall.size.height - short.size.height >= 2 * 50 - 1, "each photo is the view handed")
  }

  @Test("with no view of the app's, each photo is loaded by the card, in a frame of its own")
  func photoLoaded() throws {
    let photographed = try #require(Controls.drawn(WaypointCard(place: Self.photographed)))
    let once = try #require(
      Controls.drawn(
        WaypointCard(
          place: ItineraryPlace(
            id: "hut", lngLat: [6, 45.005], name: "Refuge",
            details: WaypointDetails(
              media: WaypointDetails.Media(photos: [
                WaypointDetails.Photo(url: "https://refuge.example/front.jpg", caption: "Front")
              ]))))))

    #expect(photographed.size.height - once.size.height >= 80, "a photo is a frame of 80 points")
  }

  @Test("a place recording nothing draws its one line, shorter than a place's sections")
  func sections() throws {
    let full = try #require(Controls.drawn(WaypointCard(place: Self.hut)))
    let bare = try #require(
      Controls.drawn(WaypointCard(place: ItineraryPlace(id: "spring", lngLat: [6, 45.015]))))

    #expect(bare.size.height < full.size.height)
    #expect(full.size.width >= 240, "a card is a panel at least")
  }
}
