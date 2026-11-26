import MountayaClient
import MountayaGeo
import RendererSupport
import SwiftUI
import Testing

@testable import MountayaElements

@Suite("ItineraryWaypointTable", .serialized)
@MainActor
struct ItineraryWaypointTableTests {
  private static let english = UnitPreferences(language: "en")

  @Test("it reads its itinerary through the cache and draws the services' chips over a row a place")
  func drawn() async throws {
    let (host, window) = Hosted.showing(
      ItineraryWaypointTable(itineraryId: "itin_test", cache: Itineraries.cache()))

    #expect(
      await MapWindow.until { Hosted.height(host) >= 32 + 3 * 44 }, "\(Hosted.height(host))")
    window.isHidden = true
  }

  /// An engine the app hands is the app's: the table draws what it reads, the app choosing the
  /// itinerary through the engine's `configure`, and never closes it.
  @Test("a table over an engine the app hands draws what it reads, and never closes it")
  func handedEngine() async throws {
    let cache = Itineraries.cache()
    let engine = ItineraryResourceEngine(cache: cache)
    let (host, window) = Hosted.showing(ItineraryWaypointTable(engine: engine))
    _ = await MapWindow.until(0.5) { false }
    #expect(Hosted.height(host) < 44, "an engine asked about nothing draws the empty line")

    engine.configure(cache: cache, itineraryId: "itin_test")
    #expect(
      await MapWindow.until { Hosted.height(host) >= 32 + 3 * 44 }, "\(Hosted.height(host))")
    host.rootView = AnyView(EmptyView())
    _ = await MapWindow.until(0.3) { false }
    engine.configure(cache: cache, itineraryId: nil)
    #expect(
      await MapWindow.until { if case .idle = engine.state { true } else { false } },
      "the table closes no engine it is handed")
    window.isHidden = true
    engine.close()
  }

  /// An invalidation asks a failed table again, and it shows its failure until the new read fails
  /// too: the app hears that second failure as well, and neither twice.
  @Test("each failure to read the itinerary is handed to onError once, one replacing a failure too")
  func failure() async throws {
    let cache = Itineraries.unreadable()
    let failures = Held<[String]>([])
    let (_, window) = Hosted.showing(
      ItineraryWaypointTable(
        itineraryId: "itin_test", cache: cache,
        onError: { failures.value.append(String(describing: type(of: $0))) }))
    #expect(await MapWindow.until { failures.value == ["Unreadable"] }, "\(failures.value)")

    cache.invalidate(itineraryId: "itin_test")
    #expect(
      await MapWindow.until { failures.value == ["Unreadable", "Unreadable"] },
      "\(failures.value)")
    // Long enough for a failure handed twice to be heard twice.
    _ = await MapWindow.until(1) { false }
    #expect(failures.value == ["Unreadable", "Unreadable"])
    window.isHidden = true
  }

  @Test("a services chip keeps its 32-point capsule and is pressed in the touch target")
  func chipTarget() throws {
    let picked = try #require(Controls.drawn(AmenityChip(label: "Water", isPicked: true) {}))

    #expect(picked.size.height == 44 && picked.size.width >= 44)
    let middle = picked.size.width / 2
    #expect(
      Pixels.pixel(picked, at: CGPoint(x: middle, y: 9))?.isNear(Controls.color("#1c7ed6"))
        == true, "the capsule on the accent, picked")
    #expect(Pixels.pixel(picked, at: CGPoint(x: middle, y: 3))?.alpha == 0)
  }

  @Test("a chip pressed toggles its service in the choice the app holds, at its end")
  func press() {
    let picked = Held<[RestSchema.WaypointAmenity]>([])
    let table = ItineraryWaypointTable(
      itineraryId: "itin_test", cache: Itineraries.cache(), picked: picked.binding)

    table.press(.water, picked: [])
    #expect(picked.value == [.water])
    table.press(.toilets, picked: picked.value)
    #expect(picked.value == [.water, .toilets])
    table.press(.water, picked: picked.value)
    #expect(picked.value == [.toilets])
  }

  @Test("a cell writes the place's figures in the reader's units and its services by name")
  func text() {
    let scope = ElementsScope.standard
    let write = { (cell: WaypointRowCell) in
      ItineraryWaypointTable.text(cell, units: Self.english, scope: scope)
    }

    #expect(write(.waypoint(glyph: "pin", name: nil)) == "Unnamed waypoint")
    #expect(write(.waypoint(glyph: "pin", name: "Refuge")) == "Refuge")
    #expect(write(.distance(total: 556)) == "0.6 km")
    #expect(write(.elevation(ascent: 200, descent: nil)) == "+200 m")
    #expect(write(.elevation(ascent: 200, descent: 150)) == "+200 m -150 m")
    #expect(write(.altitude(1_400)) == "1,400 m")
    #expect(write(.amenities(["water", "hot-meal"])) == "Water, Hot meal")
    #expect(write(.cutoff(moment: "18:00")) == "18:00")
    #expect(write(.cutoff(moment: nil)).isEmpty, "no formatter, no moment")
    #expect(
      write(
        .properties([
          WaypointField(key: "beds", label: "Beds", value: "24"),
          WaypointField(key: "warden", label: "Warden", value: "Anne"),
        ])) == "Beds: 24\nWarden: Anne")
    #expect(write(.profile(lit: ProfileRange(from: 0, to: 1))).isEmpty)
  }
}
