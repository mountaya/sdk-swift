import MountayaClient
import MountayaGeo
import RendererSupport
import SwiftUI
import Testing

@testable import MountayaElements

@Suite("ItinerarySegmentTable", .serialized)
@MainActor
struct ItinerarySegmentTableTests {
  private static let english = UnitPreferences(language: "en")

  @Test("it reads its itinerary through the cache and draws a row per leg, the empty line for none")
  func drawn() async throws {
    let (host, window) = Hosted.showing(
      ItinerarySegmentTable(itineraryId: "itin_test", cache: Itineraries.cache()))
    #expect(
      await MapWindow.until { Hosted.height(host) >= 2 * 44 + 20 }, "\(Hosted.height(host))")
    window.isHidden = true

    var bare = Itineraries.itinerary
    bare.segments = []
    let (empty, emptyWindow) = Hosted.showing(
      ItinerarySegmentTable(itineraryId: "itin_test", cache: Itineraries.cache(bare)))
    _ = await MapWindow.until(1) { false }
    #expect(Hosted.height(empty) < 44, "the empty line alone: \(Hosted.height(empty))")
    emptyWindow.isHidden = true
  }

  /// An invalidation asks a failed table again, and it shows its failure until the new read fails
  /// too: the app hears that second failure as well, and neither twice.
  @Test("each failure to read the itinerary is handed to onError once, one replacing a failure too")
  func failure() async throws {
    let cache = Itineraries.unreadable()
    let failures = Held<[String]>([])
    let (_, window) = Hosted.showing(
      ItinerarySegmentTable(
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

  /// An engine the app hands is the app's: the table draws what it reads, the app choosing the
  /// itinerary through the engine's `configure`, and never closes it.
  @Test("a table over an engine the app hands draws what it reads, and never closes it")
  func handedEngine() async throws {
    let cache = Itineraries.cache()
    let engine = ItineraryResourceEngine(cache: cache)
    let (host, window) = Hosted.showing(ItinerarySegmentTable(engine: engine))
    _ = await MapWindow.until(0.5) { false }
    #expect(Hosted.height(host) < 44, "an engine asked about nothing draws the empty line")

    engine.configure(cache: cache, itineraryId: "itin_test")
    #expect(
      await MapWindow.until { Hosted.height(host) >= 2 * 44 + 20 }, "\(Hosted.height(host))")
    host.rootView = AnyView(EmptyView())
    _ = await MapWindow.until(0.3) { false }
    engine.configure(cache: cache, itineraryId: nil)
    #expect(
      await MapWindow.until { if case .idle = engine.state { true } else { false } },
      "the table closes no engine it is handed")
    window.isHidden = true
    engine.close()
  }

  @Test("a cell writes its figure over the running one, in the reader's units")
  func text() {
    #expect(ItinerarySegmentTable.text(.segment(name: "Climb"), units: Self.english) == ["Climb"])
    #expect(
      ItinerarySegmentTable.text(.distance(leg: 1_112, total: 2_224), units: Self.english)
        == ["1.1 km", "2.2 km"])
    #expect(
      ItinerarySegmentTable.text(.distance(leg: 1_112, total: nil), units: Self.english)
        == ["1.1 km"])
    #expect(
      ItinerarySegmentTable.text(
        .elevation(ascent: 400, descent: 150, totalAscent: 650), units: Self.english)
        == ["+400 m -150 m", "+650 m"])
    #expect(
      ItinerarySegmentTable.text(
        .altitude(band: AltitudeRange(min: 1_000, max: 1_400), single: nil), units: Self.english)
        == ["1,000\u{2013}1,400 m"])
    #expect(
      ItinerarySegmentTable.text(.altitude(band: nil, single: 1_000), units: Self.english)
        == ["1,000 m"])
    #expect(
      ItinerarySegmentTable.text(
        .difficulty(text: .hiking), units: Self.english) == ["hiking"])
    #expect(
      ItinerarySegmentTable.text(
        .profile(lit: ProfileRange(from: 0, to: 1), color: nil), units: Self.english
      ).isEmpty, "a sparkline writes nothing")
  }
}
