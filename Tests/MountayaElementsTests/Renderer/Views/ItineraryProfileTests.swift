import MountayaClient
import MountayaGeo
import RendererSupport
import SwiftUI
import Testing

@testable import MountayaElements

/// The redraws a scrub may cost of the curve and of every part of the profile the cursor does not
/// move: none. The curve is a function of the itinerary and the window alone, built once and drawn
/// into an image once, and the chart, its pins, its services, the strip under a card at the
/// cursor, the axes, the navigator, the chips and the bands state nothing a scrub moves, so each
/// redraw of one is work repeated for every pointer position.
private let profileCursorBudget = 0

/// The evaluations of a profile's root a scrub may cost: none. The cursor is held where the parts
/// that read it read it, the cursor's layer, the card at it, the strip stating it and the map's
/// marker, and a redraw of the root reads the whole itinerary again and redraws every part of the
/// profile, for every pointer position.
private let scrubRootBudget = 0

@Suite("ItineraryProfile", .serialized)
@MainActor
struct ItineraryProfileTests {
  private static let english = UnitPreferences(language: "en")

  /// Scrubbed is a profile hosted in a window as an app shows one: the probe its views report to,
  /// the store of its curve, and the map its scrub writes to.
  private struct Scrubbed {
    let probe: RenderProbe
    let curves: ProfileCurves
    let map: MapEngine
    let host: UIHostingController<AnyView>
    let window: UIWindow
  }

  /// scrubbed shows the test itinerary's profile, drawing `parts` and `bands`, once it has drawn
  /// its curve and its cursor's layer.
  private func scrubbed(parts: ProfileParts, bands: [ProfileClass] = []) async throws -> Scrubbed {
    let probe = RenderProbe()
    let map = try Maps.engine()
    let (host, window) = Hosted.showing(
      ItineraryProfile(
        itineraryId: "itin_test", cache: Itineraries.cache(), map: map, bands: bands, parts: parts
      )
      .environment(\.renderProbe, probe))
    try #require(
      await MapWindow.until {
        (probe.curves?.curveDrawn ?? 0) >= 1 && (probe.curves?.cursorDrawn ?? 0) >= 1
      }, "the profile never drew its curve")
    // Long enough for every first drawing to land.
    _ = await MapWindow.until(0.3) { false }
    let curves = try #require(probe.curves)
    return Scrubbed(probe: probe, curves: curves, map: map, host: host, window: window)
  }

  /// scrub moves a pointer over the profile's chart for sixty frames, three moves over the column
  /// of one sample a frame and another sample each frame, lets SwiftUI draw each frame, and
  /// answers the sample each frame stood on.
  private func scrub(_ profile: Scrubbed) async -> [Int] {
    // Samples 2 and 3 are the col, where the climb ends and the descent starts, at one place: the
    // cursor bounces across the others, so every frame moves it.
    let samples = [0, 1, 2, 4, 5, 4, 2, 1]
    var stood: [Int] = []
    for frame in 0..<60 {
      let index = samples[frame % samples.count]
      let drawn = profile.curves.cursorDrawn
      for _ in 0..<3 {
        profile.probe.scrub?(index)
      }
      #expect(await MapWindow.until { profile.curves.cursorDrawn > drawn }, "frame \(frame)")
      stood.append(index)
    }
    return stood
  }

  @Test(
    "hot-path budget profile-cursor: a scrub redraws the cursor, never the curve or a still part")
  func profileCursor() async throws {
    let profile = try await scrubbed(
      parts: [.amenities, .tooltip, .sections, .navigator, .elevationAxis, .distanceAxis],
      bands: [ProfileClass(from: 0, to: 1_000, color: "#fa5252", label: "Steep")])
    let still = [
      "ProfileChart", "ProfilePin", "AmenityStackBadges", "ProfileStatStrip", "ProfileDistanceAxis",
      "ProfileNavigator", "ProfileSections", "ProfileStretchStrip",
    ]
    let before = profile.probe.counts
    let curve = (
      built: profile.curves.built, drawn: profile.curves.curveDrawn,
      cursor: profile.curves.cursorDrawn
    )
    #expect(
      still.filter { before[$0, default: 0] == 0 }.isEmpty, "every part is drawn: \(before)")

    let frames = await scrub(profile).count

    // The work happened: the cursor was drawn again on every frame, and the card at it with it.
    #expect(profile.curves.cursorDrawn - curve.cursor >= frames)
    #expect(
      profile.probe["ProfileReadoutCard"] - before["ProfileReadoutCard", default: 0] >= frames)
    // Nothing the cursor does not move was drawn again: the curve built or drawn, or a part of it.
    let redrawn = still.map { ($0, profile.probe[$0] - before[$0, default: 0]) }.filter { $0.1 > 0 }
    let curveRedrawn =
      (profile.curves.built - curve.built) + (profile.curves.curveDrawn - curve.drawn)
    #expect(
      curveRedrawn + redrawn.map(\.1).reduce(0, +) <= profileCursorBudget,
      "over \(frames) frames: the curve \(curveRedrawn), \(redrawn)")
    profile.window.isHidden = true
  }

  @Test("hot-path budget scrub-root: sixty frames of a scrub never redraw the profile's root")
  func scrubRoot() async throws {
    let profile = try await scrubbed(parts: .standard)
    let before = profile.probe.counts

    let stood = await scrub(profile)

    // The work happened: the strip stated every sample stood on, and the map's marker stands on the
    // last.
    let strip = profile.probe["ProfileStatStrip"] - before["ProfileStatStrip", default: 0]
    #expect(strip >= stood.count, "the strip was drawn \(strip) times")
    let points = ItineraryDrawing(resolved: Itineraries.resolved, legs: nil).series.points
    #expect(
      profile.map.state.markers.first { $0.id == profileCursorMarkerId }?.position
        == points[stood.last ?? 0].lngLat)
    // The root drew none of it.
    let root = profile.probe["ItineraryProfile"] - before["ItineraryProfile", default: 0]
    #expect(root <= scrubRootBudget, "the root was drawn \(root) times over \(stood.count) frames")
    profile.window.isHidden = true
  }

  @Test(
    "it reads its itinerary through the cache and draws its plot, none for one with no altitude")
  func drawn() async throws {
    let (host, window) = Hosted.showing(
      ItineraryProfile(itineraryId: "itin_test", cache: Itineraries.cache()))
    #expect(
      await MapWindow.until { Hosted.height(host) > 1_000 },
      "the plot fills the height it is offered: \(Hosted.height(host))")
    window.isHidden = true

    let (flat, flatWindow) = Hosted.showing(
      ItineraryProfile(itineraryId: "itin_test", cache: Itineraries.cache(Itineraries.flat)))
    // The same wait, so the answer has landed before the layout is read.
    _ = await MapWindow.until(1) { false }
    #expect(Hosted.height(flat) < 200, "its strip and its empty line: \(Hosted.height(flat))")
    flatWindow.isHidden = true
  }

  /// An invalidation asks a failed profile again, and it shows its failure until the new read fails
  /// too: the app hears that second failure as well, and neither twice.
  @Test("each failure to read the itinerary is handed to onError once, one replacing a failure too")
  func failure() async throws {
    let cache = Itineraries.unreadable()
    let failures = Held<[String]>([])
    let (_, window) = Hosted.showing(
      ItineraryProfile(
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

  /// An engine the app hands is the app's: the profile draws what it reads, the app choosing the
  /// itinerary through the engine's `configure`, and never closes it; its failures are handed on.
  @Test("a profile over an engine the app hands draws what it reads, and never closes it")
  func handedEngine() async throws {
    let cache = Itineraries.cache()
    let engine = ItineraryResourceEngine(cache: cache)
    let probe = RenderProbe()
    let (host, window) = Hosted.showing(
      ItineraryProfile(engine: engine).environment(\.renderProbe, probe))
    _ = await MapWindow.until(0.5) { false }
    #expect(probe.curves == nil, "an engine asked about nothing draws no curve")

    engine.configure(cache: cache, itineraryId: "itin_test")
    #expect(
      await MapWindow.until { (probe.curves?.curveDrawn ?? 0) >= 1 }, "the app chose the itinerary")
    host.rootView = AnyView(EmptyView())
    _ = await MapWindow.until(0.3) { false }
    engine.configure(cache: cache, itineraryId: nil)
    #expect(
      await MapWindow.until { if case .idle = engine.state { true } else { false } },
      "the profile closes no engine it is handed")
    window.isHidden = true
    engine.close()
  }

  @Test("each failure an engine the app hands shows is handed to onError once")
  func handedEngineFailure() async throws {
    let cache = Itineraries.unreadable()
    let engine = ItineraryResourceEngine(cache: cache)
    let failures = Held<[String]>([])
    let (_, window) = Hosted.showing(
      ItineraryProfile(
        engine: engine, onError: { failures.value.append(String(describing: type(of: $0))) }))
    _ = await MapWindow.until(0.3) { false }

    engine.configure(cache: cache, itineraryId: "itin_test")
    #expect(await MapWindow.until { failures.value == ["Unreadable"] }, "\(failures.value)")
    _ = await MapWindow.until(0.5) { false }
    #expect(failures.value == ["Unreadable"])
    window.isHidden = true
    engine.close()
  }

  @Test("the chips under the chart grow with the reader's text size, so their lines are whole")
  func sectionsTextSize() throws {
    let drawing = ItineraryDrawing(resolved: Itineraries.resolved, legs: nil)
    let sections = ProfileSections(
      rows: placeSpans(
        drawing.rows, totalDistance: drawing.series.totalDistance, window: drawing.whole),
      units: Self.english
    ).frame(width: 300)
    let standard = try #require(Controls.drawn(sections))
    let large = try #require(
      Controls.drawn(sections.environment(\.dynamicTypeSize, .accessibility3)))

    #expect(standard.size.height == 36)
    #expect(large.size.height > 36, "\(large.size)")
  }

  /// A leg's chip hands over the id the row-match names, a collapsed group's `group:` id among
  /// them, and writes nothing to the map: the press is the app's (`sdk/SPEC.md` §7).
  @Test("a pressed chip hands its leg's id to onSegmentTap, a group's own id, and nothing disabled")
  func sectionPress() throws {
    let drawing = ItineraryDrawing(resolved: Itineraries.resolved, legs: nil)
    let leg = try #require(drawing.rows.first)
    var group = leg
    group.id = segmentGroupIdPrefix + "approach"
    group.memberIds = [leg.id, "seg_b"]
    let pressed = Held<[String]>([])
    let tap: (String) -> Void = { pressed.value.append($0) }

    ProfileSections.press(leg, isEnabled: true, onSegmentTap: tap)
    ProfileSections.press(group, isEnabled: true, onSegmentTap: tap)
    #expect(pressed.value == [leg.id, "group:approach"])
    #expect(rowStandsFor(group, id: pressed.value[1]) && rowStandsFor(leg, id: pressed.value[0]))

    ProfileSections.press(leg, isEnabled: false, onSegmentTap: tap)
    ProfileSections.press(leg, isEnabled: true, onSegmentTap: nil)
    #expect(pressed.value == [leg.id, "group:approach"], "a disabled profile presses nothing")
  }

  /// A press of a chip is the app's: the map the profile links stays as it was, its markers and its
  /// emphasis among it.
  @Test("a profile whose chips the app listens to draws them and writes nothing to its map")
  func sectionsHosted() async throws {
    let map = try Maps.engine()
    let pressed = Held<[String]>([])
    let probe = RenderProbe()
    let (_, window) = Hosted.showing(
      ItineraryProfile(
        itineraryId: "itin_test", cache: Itineraries.cache(), map: map,
        parts: [.sections], onSegmentTap: { pressed.value.append($0) }
      )
      .environment(\.renderProbe, probe))
    #expect(await MapWindow.until { probe["ProfileSections"] >= 1 }, "the chips are drawn")
    let held = map.state
    let leg = try #require(ItineraryDrawing(resolved: Itineraries.resolved, legs: nil).rows.first)
    ProfileSections.press(leg, isEnabled: true) { pressed.value.append($0) }
    _ = await MapWindow.until(0.2) { false }
    #expect(pressed.value == [leg.id])
    #expect(map.state == held, "nothing is written to the map")
    window.isHidden = true
  }

  @Test("the strip writes each figure in the reader's units, a difficulty as the itinerary does")
  func strip() {
    #expect(ProfileStatStrip.value(.distance(2_224), units: Self.english) == "2.2 km")
    #expect(ProfileStatStrip.value(.ascent(400), units: Self.english) == "400 m")
    #expect(ProfileStatStrip.value(.descent(300), units: Self.english) == "300 m")
    #expect(ProfileStatStrip.value(.elevation(1_250), units: Self.english) == "1,250 m")
    #expect(
      ProfileStatStrip.value(.duration(5_400), units: Self.english)
        == formatDuration(5_400, units: Self.english))
    #expect(
      ProfileStatStrip.value(.difficulty(.mountainHiking), units: Self.english)
        == "mountain-hiking")
  }
}
