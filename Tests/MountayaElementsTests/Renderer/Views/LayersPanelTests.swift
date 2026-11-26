import Foundation
import MountayaClient
import MountayaElements
import MountayaGeo
import RendererSupport
import SwiftUI
import Testing

@testable import MountayaElements

/// The redraws a redraw of the panel may cost of a card or a switch it changed nothing of: none.
/// Each is a part of its own, handed equal values and pressing through the panel as it is now, and
/// a panel redraws for a sibling's press and its host's own redraw.
private let panelRowsBudget = 0

@Suite("LayersPanel", .serialized)
@MainActor
struct LayersPanelTests {
  /// Redrawn is an app's view holding a layers panel, which draws it again each time it draws, with
  /// handlers of its own made anew each time, as an app's closures are.
  private struct Redrawn: View {
    let selection: LayersSelectionEngine
    let redraws: Held<Int>
    let probe: RenderProbe

    var body: some View {
      let drawn = redraws.value
      LayersPanel(selection: selection, isLocked: { _ in drawn < 0 }, onLockedTap: { _ in })
        .environment(\.renderProbe, probe)
    }
  }

  @Test(
    "hot-path budget panel-rows: a host's redraws and a press redraw no card or switch they did not change"
  )
  func panelRows() async throws {
    let selection = LayersSelectionEngine(map: Answering())
    await settled()
    let probe = RenderProbe()
    let redraws = Held(0)
    let (host, window) = Hosted.showing(
      Redrawn(selection: selection, redraws: redraws, probe: probe))
    let rows = [
      "LayersPanelCard Topographic", "LayersPanelCard Slope", "LayersPanelSwitch Hillshade",
    ]
    try #require(await MapWindow.until { rows.allSatisfy { probe[$0] >= 1 } }, "\(probe.counts)")
    _ = await MapWindow.until(0.3) { false }
    let before = probe.counts

    // Twenty redraws of the host, each handing the panel handlers made anew.
    for redraw in 1...20 {
      let panel = probe["LayersPanel"]
      redraws.value = redraw
      #expect(await MapWindow.until { probe["LayersPanel"] > panel }, "redraw \(redraw)")
    }
    // A press on the slope's card, which selects it and changes that card alone.
    let slope = probe["LayersPanelCard Slope"]
    LayersPanel.press(.command(.overlay, slug: "slopes"), selection: selection, onLockedTap: nil)
    #expect(await MapWindow.until { probe["LayersPanelCard Slope"] > slope })
    _ = await MapWindow.until(0.3) { false }

    // The work happened: the panel was drawn for each redraw of its host and for the press, and the
    // card pressed was drawn again, selected.
    #expect(selection.state.overlay == "slopes")
    #expect(probe["LayersPanel"] - before["LayersPanel", default: 0] >= 21)
    let redrawn = rows.map { ($0, probe[$0] - before[$0, default: 0]) }
    // Only the slope's card changed, once.
    let unchanged = redrawn.map(\.1).reduce(0, +) - 1
    #expect(unchanged <= panelRowsBudget, "cards and switches drawn again: \(redrawn)")
    window.isHidden = true
    _ = host
    selection.close()
  }

  /// Answering is a map a selection drives, which answers every command at once and records it.
  @MainActor
  final class Answering: LayersSelectionTarget {
    private(set) var calls: [String] = []
    var terrain: String? = "topo"

    func loadLayers() async throws -> TileSchema.Layers {
      try JSONDecoder().decode(TileSchema.Layers.self, from: Data(Self.catalogue.utf8))
    }

    func setTerrain(_ slug: String?) async throws { calls.append("terrain:\(slug ?? "-")") }
    func setOverlay(_ slug: String) async throws { calls.append("overlay:\(slug)") }
    func clearOverlay() async throws { calls.append("overlay:-") }
    func addEnrichment(_ slug: String) async throws { calls.append("add:\(slug)") }
    func removeEnrichment(_ slug: String) async throws { calls.append("remove:\(slug)") }
    func setInstant(_ instant: Date?) async throws {
      calls.append("instant:\(instant.map { "\($0.timeIntervalSince1970)" } ?? "-")")
    }

    /// catalogue holds a terrain, two classic categories, the conditions and the hazards, and the
    /// enrichments, the points of interest among them.
    static let catalogue = #"""
      {"elevation": {"id": "e", "tile_size": 512, "url": "https://tiles.test/elevation.json"},
       "itineraries": {"capabilities": {"client": {"timestamp": false}, "server": {"timestamp": false}},
         "content_type": "application/x-protobuf", "id": "i", "locales": {}, "slug": "itineraries", "sources": []},
       "zones": {"capabilities": {"client": {"timestamp": false}, "server": {"timestamp": false}},
         "content_type": "application/x-protobuf", "id": "z", "locales": {}, "slug": "zones", "sources": []},
       "overlays": [
         {"id": "c", "slug": "conditions", "locales": {"en": {"name": "Conditions"}}, "children": [
           {"capabilities": {"client": {"timestamp": false}, "server": {"timestamp": false}},
            "content_type": "application/x-protobuf", "id": "s", "slug": "slopes",
            "locales": {"en": {"name": "Slope"}, "fr": {"name": "Pente"}}, "sources": []}]},
         {"id": "h", "slug": "hazards", "locales": {"en": {"name": "Hazards"}}, "children": [
           {"capabilities": {"client": {"timestamp": false}, "server": {"timestamp": true}},
            "content_type": "application/x-protobuf", "id": "a", "slug": "avalanche",
            "locales": {"en": {"name": "Avalanche risk"}}, "sources": []}]},
         {"id": "x", "slug": "enrichment", "locales": {}, "children": [
           {"capabilities": {"client": {"timestamp": false}, "server": {"timestamp": false}},
            "content_type": "application/x-protobuf", "id": "h", "slug": "hillshade",
            "locales": {"en": {"name": "Hillshade"}}, "sources": []},
           {"capabilities": {"client": {"timestamp": false}, "server": {"timestamp": false}},
            "content_type": "application/x-protobuf", "id": "p", "slug": "pois",
            "locales": {"en": {"name": "Points of interest"}}, "sources": []}]}],
       "terrains": [
         {"id": "t", "slug": "topo", "locales": {"en": {"name": "Topographic"}}, "variants": {
           "light": {"style": {"url": "https://tiles.test/topo/light/style"},
             "tiles": {"size": 512, "url": "https://tiles.test/topo/light/tiles.json"}},
           "dark": {"style": {"url": "https://tiles.test/topo/dark/style"},
             "tiles": {"size": 512, "url": "https://tiles.test/topo/dark/tiles.json"}}}}]}
      """#
  }

  /// Stopped is a clock of a host's own, stopped at `now`, 2026-03-14T09:26:53.900Z unless it is
  /// handed another reading.
  struct Stopped: WallClock {
    var now = Date(timeIntervalSince1970: 1_773_480_413.9)
  }

  /// Offered is a layers panel offering the time, read through `probe`, on the clock `clock`.
  private struct Offered: View {
    let selection: LayersSelectionEngine
    let probe: RenderProbe
    var clock = Stopped()

    var body: some View {
      LayersPanel(selection: selection, offersTime: true)
        .environment(\.renderProbe, probe)
        .environment(\.mountayaClock, clock)
    }
  }

  /// readout is the readout the time section last reported to `probe`, or nil for none.
  private static func readouts(_ probe: RenderProbe) -> [String] {
    probe.counts.keys.filter { $0.hasPrefix("LayersPanelTime ") }.map {
      String($0.dropFirst("LayersPanelTime ".count))
    }
  }

  @Test(
    "the studio's four sections: the terrains' cards, the switches, the open category's cards, the time"
  )
  func sections() async throws {
    let selection = LayersSelectionEngine(map: Answering())
    await settled()
    let probe = RenderProbe()
    let (host, window) = Hosted.showing(Offered(selection: selection, probe: probe))
    let shown = [
      "LayersPanelCard Topographic", "LayersPanelSwitch Hillshade", "LayersPanelCard Slope",
    ]
    try #require(await MapWindow.until { shown.allSatisfy { probe[$0] >= 1 } }, "\(probe.counts)")
    #expect(await MapWindow.until { !Self.readouts(probe).isEmpty }, "\(probe.counts)")
    #expect(Self.readouts(probe).allSatisfy { $0.hasSuffix(" · Now") }, "\(Self.readouts(probe))")
    #expect(probe["LayersPanelSwitch Points of interest"] == 0, "their own picker drives them")
    #expect(probe["LayersPanelCard Avalanche risk"] == 0, "a category at a time")

    // The overlays open on the category holding the overlay selected.
    selection.setOverlay("avalanche")
    #expect(await MapWindow.until { probe["LayersPanelCard Avalanche risk"] >= 1 })
    window.isHidden = true
    _ = host
    selection.close()
  }

  @Test("no time is offered unless the host offers it")
  func noTime() async throws {
    let selection = LayersSelectionEngine(map: Answering())
    await settled()
    let probe = RenderProbe()
    let (host, window) = Hosted.showing(
      LayersPanel(selection: selection).environment(\.renderProbe, probe))
    try #require(await MapWindow.until { probe["LayersPanelCard Topographic"] >= 1 })
    _ = await MapWindow.until(0.3) { false }
    #expect(Self.readouts(probe).isEmpty)
    window.isHidden = true
    _ = host
    selection.close()
  }

  @Test("the time is laid out around the environment's clock, and held where it reads none")
  func clock() async throws {
    let selection = LayersSelectionEngine(map: Answering())
    await settled()
    let probe = RenderProbe()
    // The track around the stopped clock's reading, each stop's moment in the zone the device keeps.
    let track = timeSliderWindow(now: Stopped().now)
    func read(_ value: Int) -> String {
      LayersPanelTime.readout(
        timeSliderReadout(track, at: value), in: .standard, timeZone: deviceTimeZone())
    }
    let (host, window) = Hosted.showing(Offered(selection: selection, probe: probe))
    try #require(
      await MapWindow.until { Self.readouts(probe).contains(read(track.nowValue)) },
      "\(Self.readouts(probe))")

    // A pin two days ahead of the stopped clock reads its moment and its distance from it.
    selection.setInstant(Date(timeIntervalSince1970: 1_773_480_413.9 + 48 * 3600))
    let ahead = read(track.nowValue + 48)
    #expect(ahead.hasSuffix(" · in 2 days"), "\(ahead)")
    #expect(
      await MapWindow.until { Self.readouts(probe).contains(ahead) }, "\(Self.readouts(probe))")
    window.isHidden = true
    _ = host

    // A clock that reads no instant holds the slider: its thumb reads its offset alone.
    let held = RenderProbe()
    let (other, shown) = Hosted.showing(
      Offered(
        selection: selection, probe: held, clock: Stopped(now: Date(timeIntervalSince1970: .nan))))
    #expect(
      await MapWindow.until { Self.readouts(held) == ["Now"] }, "\(Self.readouts(held))")
    shown.isHidden = true
    _ = other
    selection.close()
  }

  /// switches is every platform switch drawn under `view`, in the order its subviews are walked.
  private static func switches(in view: UIView) -> [UISwitch] {
    var found: [UISwitch] = []
    var walked = [view]
    while let next = walked.popLast() {
      if let toggle = next as? UISwitch {
        found.append(toggle)
      }
      walked += next.subviews
    }
    return found
  }

  /// rgb is the red, green and blue of `color`, each from 0 to 255, rounded.
  private static func rgb(_ color: UIColor?) -> [Int] {
    var red: CGFloat = -1
    var green: CGFloat = -1
    var blue: CGFloat = -1
    var alpha: CGFloat = -1
    _ = color?.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    return [red, green, blue].map { Int(($0 * 255).rounded()) }
  }

  @Test(
    "an enrichment is the platform's switch in the accent, on while turned on, a locked one none")
  func switches() async throws {
    let selection = LayersSelectionEngine(map: Answering())
    await settled()
    selection.toggleEnrichment("hillshade")
    let (host, window) = Hosted.showing(LayersPanel(selection: selection))
    try #require(await MapWindow.until { Self.switches(in: host.view).count == 1 })
    let toggle = try #require(Self.switches(in: host.view).first)

    #expect(toggle.isOn, "hillshade is turned on")
    // The accent tints the switch's track while it is on, where the platform's would be green.
    let accent = Controls.color(themeTokenValue(ElementTokens.standard.accent, in: .light).hex)
    let tint = Self.rgb(toggle.onTintColor ?? toggle.tintColor)
    #expect(
      zip(tint, [accent.red, accent.green, accent.blue]).allSatisfy { abs($0 - $1) <= 2 },
      "\(tint)")

    // Turned off through the selection, the switch follows it.
    selection.toggleEnrichment("hillshade")
    #expect(await MapWindow.until { Self.switches(in: host.view).first?.isOn == false })
    window.isHidden = true
    _ = host

    // A locked enrichment shows its lock in place of a switch.
    let probe = RenderProbe()
    let (locked, shown) = Hosted.showing(
      LayersPanel(selection: selection, isLocked: { $0 == "hillshade" })
        .environment(\.renderProbe, probe))
    try #require(await MapWindow.until { probe["PanelRow Hillshade"] >= 1 }, "\(probe.counts)")
    #expect(Self.switches(in: locked.view).isEmpty)
    shown.isHidden = true
    selection.close()
  }

  @Test("a press asks the selection's command for its card or switch, which drives the map")
  func press() async {
    let map = Answering()
    let selection = LayersSelectionEngine(map: map)
    var locked: [String] = []
    await settled()

    LayersPanel.press(.command(.overlay, slug: "slopes"), selection: selection, onLockedTap: nil)
    LayersPanel.press(
      .command(.enrichment, slug: "hillshade"), selection: selection, onLockedTap: nil)
    LayersPanel.press(.command(.terrain, slug: "topo"), selection: selection, onLockedTap: nil)
    LayersPanel.press(.command(.time, slug: "now"), selection: selection, onLockedTap: nil)
    LayersPanel.press(
      .locked("snow-depth"), selection: selection, onLockedTap: { locked.append($0) })
    await settled()

    #expect(selection.state.overlay == "slopes")
    #expect(selection.state.enrichments == ["hillshade"])
    #expect(map.calls == ["overlay:slopes", "add:hillshade", "terrain:topo"])
    #expect(locked == ["snow-depth"], "a locked entry selects nothing, its press handed on")
    selection.close()
  }

  @Test("a card shows the picture the host hands for its entry, and its name alone otherwise")
  func pictures() async throws {
    let selection = LayersSelectionEngine(map: Answering())
    await settled()
    let named = try #require(Controls.drawn(LayersPanel(selection: selection)))
    let pictured = try #require(
      Controls.drawn(
        LayersPanel(
          selection: selection,
          thumbnail: { choice, _ in
            choice == .terrain ? Image(systemName: "mountain.2.fill") : nil
          })))

    #expect(pictured.size.height > named.size.height, "\(pictured.size) over \(named.size)")
    selection.close()
  }

  @Test("the panel draws the selection's catalogue on the panel's ground")
  func drawn() async throws {
    let selection = LayersSelectionEngine(map: Answering())
    await settled()
    let image = try #require(Controls.drawn(LayersPanel(selection: selection)))
    let dark = try #require(Controls.drawn(LayersPanel(selection: selection), scheme: .dark))

    #expect(image.size.width >= 240)
    #expect(Pixels.pixel(image, at: CGPoint(x: 4, y: 4))?.isNear(Controls.color("#ffffff")) == true)
    #expect(Pixels.pixel(dark, at: CGPoint(x: 4, y: 4))?.isNear(Controls.color("#25262b")) == true)
    selection.close()
  }
}
