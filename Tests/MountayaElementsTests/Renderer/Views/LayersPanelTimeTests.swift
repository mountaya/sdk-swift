import Foundation
import MountayaClient
import MountayaElements
import MountayaGeo
import RendererSupport
import SwiftUI
import Testing

@testable import MountayaElements

@Suite("LayersPanelTime", .serialized)
@MainActor
struct LayersPanelTimeTests {
  /// now is the clock's reading the track is laid out around, 2026-03-14T09:26:53.900Z.
  private static let now = Date(timeIntervalSince1970: 1_773_480_413.9)
  private static let window = timeSliderWindow(now: now)

  /// Pinned is a map a selection drives, which answers every pin at once and records it.
  @MainActor
  final class Pinned: LayersSelectionTarget {
    private(set) var pins: [Date?] = []
    let terrain: String? = nil

    func loadLayers() async throws -> TileSchema.Layers { throw CancellationError() }
    func setTerrain(_ slug: String?) async throws {}
    func setOverlay(_ slug: String) async throws {}
    func clearOverlay() async throws {}
    func addEnrichment(_ slug: String) async throws {}
    func removeEnrichment(_ slug: String) async throws {}
    func setInstant(_ instant: Date?) async throws { pins.append(instant) }
  }

  @Test("a release pins its stop's instant through the selection, and none on the stop of now")
  func release() async {
    let map = Pinned()
    let selection = LayersSelectionEngine(map: map)

    LayersPanelTime.release(77, of: Self.window, to: selection)
    #expect(selection.state.instant == Self.window.date(at: 77))
    LayersPanelTime.release(71, of: Self.window, to: selection)
    #expect(selection.state.instant == nil, "now pins none, so the map follows the clock")
    LayersPanelTime.release(
      80, of: timeSliderWindow(now: Date(timeIntervalSince1970: .nan)), to: selection)
    await settled()

    #expect(map.pins == [Self.window.date(at: 77), nil], "a track of no instant commits nothing")
    selection.close()
  }

  @Test(
    "an arrow key or an adjustment steps one stop, a drag lands on the nearest, held to the track")
  func stops() {
    #expect(LayersPanelTime.step(of: .leftArrow) == -1)
    #expect(LayersPanelTime.step(of: .downArrow) == -1)
    #expect(LayersPanelTime.step(of: .rightArrow) == 1)
    #expect(LayersPanelTime.step(of: .upArrow) == 1)
    #expect(LayersPanelTime.step(of: .space) == nil)
    #expect(LayersPanelTime.stepped(71, by: 1, maxValue: 215) == 72)
    #expect(LayersPanelTime.stepped(71, by: -1, maxValue: 215) == 70)
    #expect(LayersPanelTime.stepped(0, by: -1, maxValue: 215) == 0)
    #expect(LayersPanelTime.stepped(215, by: 1, maxValue: 215) == 215)

    let width = 2 * LayersPanelTime.inset + 215
    #expect(
      LayersPanelTime.value(at: LayersPanelTime.inset + 77.4, width: width, maxValue: 215) == 77)
    #expect(
      LayersPanelTime.value(at: LayersPanelTime.inset + 77.5, width: width, maxValue: 215) == 78)
    #expect(LayersPanelTime.value(at: -40, width: width, maxValue: 215) == 0)
    #expect(LayersPanelTime.value(at: width + 40, width: width, maxValue: 215) == 215)
    #expect(LayersPanelTime.value(at: 10, width: 0, maxValue: 215) == 0)
  }

  @Test("the readout is the moment in the zone named, then its offset in the scope's words")
  func readout() {
    let english = LayersPanelTime.readout(
      timeSliderReadout(Self.window, at: 77), in: .standard, timeZone: "UTC")
    #expect(english.hasSuffix(" · in 6 hours"), "\(english)")
    #expect(english.contains("15:26") || english.contains("3:26"), "\(english)")
    #expect(english.contains("14"), "\(english)")

    let french = scopeOf(.standard, stating: ElementsScopeStatement(language: .fr, locale: "fr-FR"))
    let ago = LayersPanelTime.readout(
      timeSliderReadout(Self.window, at: 23), in: french, timeZone: "Europe/Paris")
    #expect(ago.hasSuffix(" · il y a 2 jours"), "\(ago)")
    #expect(ago.contains("10:26"), "\(ago)")

    let alone = LayersPanelTime.readout(
      timeSliderReadout(timeSliderWindow(now: Date(timeIntervalSince1970: .nan)), at: 72),
      in: .standard, timeZone: "UTC")
    #expect(alone == "in 1 hour", "a stop that stands for no instant reads its offset alone")
    #expect(
      LayersPanelTime.readout(
        timeSliderReadout(Self.window, at: 71), in: .standard, timeZone: "UTC"
      )
      .hasSuffix(" · Now"))
    #expect(
      LayersPanelTime.readout(
        timeSliderReadout(Self.window, at: 77), in: .standard, timeZone: "Mars/Olympus_Mons")
        == "in 6 hours",
      "a moment the locale services cannot write in the zone is left out, never written another way"
    )
  }

  @Test("the thumb reads its moment in the time zone the device keeps, never the view's own")
  func deviceZone() throws {
    let device = deviceTimeZone()
    // A zone the device does not keep, which the view's environment states.
    let stated = device == "Pacific/Kiritimati" ? "Pacific/Pago_Pago" : "Pacific/Kiritimati"
    func read(in zone: String) -> String {
      LayersPanelTime.readout(
        timeSliderReadout(Self.window, at: Self.window.nowValue), in: .standard, timeZone: zone)
    }
    try #require(read(in: stated) != read(in: device), "the two zones write the moment apart")
    let zone = try #require(TimeZone(identifier: stated))
    let selection = LayersSelectionEngine(map: Pinned())
    let probe = RenderProbe()
    _ = try #require(
      Controls.drawn(
        LayersPanelTime(
          selection: selection, window: Self.window, words: ViewScope.Laid(scope: .standard)
        )
        .frame(width: 320)
        .environment(\.timeZone, zone)
        .environment(\.renderProbe, probe)))
    let drawn = probe.counts.keys.filter { $0.hasPrefix("LayersPanelTime ") }

    #expect(drawn == ["LayersPanelTime " + read(in: device)], "\(drawn)")
    selection.close()
  }

  @Test("a view's own words stand over the scope's, a counted word's template taking the count")
  func strings() {
    let laid = ViewScope.scope(.standard, strings: ["layers.timeHoursAhead": "+{count} h"])
    let readout = LayersPanelTime.readout(
      timeSliderReadout(Self.window, at: 77), in: laid, timeZone: "UTC")
    #expect(readout.hasSuffix(" · +6 h"), "\(readout)")
  }

  @Test("the caption says what the slider drives, its keys where a keyboard is at hand, its zone")
  func caption() {
    #expect(
      LayersPanelTime.caption(in: .standard, hasKeyboard: false)
        == "Choose the time for time-aware layers. Times shown in your local time zone.")
    #expect(
      LayersPanelTime.caption(in: .standard, hasKeyboard: true)
        == "Choose the time for time-aware layers. Use ← → to adjust by the hour. "
        + "Times shown in your local time zone.")
  }

  @Test("the track fills from the stop of now to the thumb, and the thumb stands at the pin's stop")
  func fill() async throws {
    let selection = LayersSelectionEngine(map: Pinned())
    // Two days ahead: the thumb stands at stop 119.
    selection.setInstant(Self.window.date(at: 119))
    let width: CGFloat = 320
    let image = try #require(
      Controls.drawn(
        LayersPanelTime(
          selection: selection, window: Self.window, words: ViewScope.Laid(scope: .standard)
        )
        .frame(width: width)))
    let accent = Controls.color(
      themeTokenValue(ElementTokens.standard.accent, in: .light).hex)
    let span = width - 2 * LayersPanelTime.inset
    func x(_ value: Int) -> CGFloat { LayersPanelTime.inset + span * CGFloat(value) / 215 }
    // The track's line stands 16 points down the slider, which closes the section.
    let line = image.size.height - LayersPanelTime.height + 16

    #expect(
      Pixels.pixel(image, at: CGPoint(x: x(100), y: line))?.isNear(accent, tolerance: 24) == true,
      "the fill between now and the thumb")
    #expect(
      Pixels.pixel(image, at: CGPoint(x: x(119) + 1, y: line))?.isNear(accent, tolerance: 24)
        == true, "the thumb at its stop")
    #expect(
      Pixels.pixel(image, at: CGPoint(x: x(40), y: line))?.isNear(accent, tolerance: 24) != true,
      "no fill behind now")
    #expect(
      Pixels.pixel(image, at: CGPoint(x: x(170), y: line))?.isNear(accent, tolerance: 24) != true,
      "no fill past the thumb")
    selection.close()
  }
}
