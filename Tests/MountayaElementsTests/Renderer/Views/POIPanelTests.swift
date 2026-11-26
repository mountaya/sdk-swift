import MountayaElements
import MountayaGeo
import RendererSupport
import SwiftUI
import Testing

@testable import MountayaElements

/// The redraws a redraw of the panel may cost of a row it changed nothing of: none. Each row is a
/// part of its own, handed equal values and pressing through the panel as it is now, and a panel
/// redraws for a zoom note, a sibling's press and its host's own redraw.
private let panelRowsBudget = 0

/// The redraws of the panel a camera driven frame by frame may cost, for each time the comparison
/// of its zoom with the note's floor flips: one, the note's. The comparison is read on every frame,
/// and a redraw of the panel on every frame redraws its rows with it.
private let zoomThresholdBudget = 1

@Suite("POIPanel", .serialized)
@MainActor
struct POIPanelTests {
  /// drawing is a map drawing the points-of-interest specification.
  private static func drawing() throws -> MapEngine {
    let map = try Maps.engine()
    try map.setSpecification(Maps.pointsOfInterest, named: "pois")
    return map
  }

  /// Redrawn is an app's view holding a points-of-interest panel, which draws it again each time it
  /// draws, with a handler of its own made anew each time, as an app's closures are.
  private struct Redrawn: View {
    let map: MapEngine
    let redraws: Held<Int>
    let probe: RenderProbe

    var body: some View {
      let drawn = redraws.value
      POIPanel(
        map: map, minZoom: 12, showsAllToggle: true, onToggleAll: { _ in _ = drawn }
      )
      .environment(\.renderProbe, probe)
    }
  }

  @Test("hot-path budget panel-rows: redraws of the panel redraw no row they did not change")
  func panelRows() async throws {
    let map = try Self.drawing()
    let probe = RenderProbe()
    let redraws = Held(0)
    let (host, window) = Hosted.showing(Redrawn(map: map, redraws: redraws, probe: probe))
    let rows = [
      "PanelRow parking", "PanelRow poi_food",
      "PanelRow " + ElementsScope.standard.word("pois.displayOnMap"),
    ]
    try #require(await MapWindow.until { rows.allSatisfy { probe[$0] >= 1 } }, "\(probe.counts)")
    _ = await MapWindow.until(0.3) { false }
    let before = probe.counts

    // Twenty redraws of the host, each handing the panel a handler made anew.
    for redraw in 1...20 {
      let panel = probe["POIPanel"]
      redraws.value = redraw
      #expect(await MapWindow.until { probe["POIPanel"] > panel }, "redraw \(redraw)")
    }
    // A press on the parking row, which hides its concept and changes that row alone.
    let parking = probe["PanelRow parking"]
    map.setKeyVisibility("parking", visible: false)
    #expect(await MapWindow.until { probe["PanelRow parking"] > parking })
    // The camera below the overlay's floor, which raises the note over the rows.
    try map.jump(to: CameraTarget(zoom: 11))
    _ = await MapWindow.until(0.5) { false }

    // The work happened: the panel was drawn for each redraw of its host, and the row pressed was
    // drawn again.
    #expect(probe["POIPanel"] - before["POIPanel", default: 0] >= 20)
    let redrawn = rows.map { ($0, probe[$0] - before[$0, default: 0]) }
    // Only the parking row changed, once.
    let unchanged = redrawn.map(\.1).reduce(0, +) - 1
    #expect(unchanged <= panelRowsBudget, "rows drawn again: \(redrawn)")
    window.isHidden = true
    _ = host
  }

  @Test(
    "hot-path budget zoom-threshold: sixty camera frames redraw the panel once, as the note flips")
  func zoomThreshold() async throws {
    let map = try Self.drawing()
    try map.jump(to: CameraTarget(zoom: 13))
    let probe = RenderProbe()
    let (host, window) = Hosted.showing(
      POIPanel(map: map, minZoom: 12).environment(\.renderProbe, probe))
    try #require(await MapWindow.until { probe["POIPanel"] >= 1 })
    _ = await MapWindow.until(0.3) { false }
    let before = probe.counts
    /// since is how often the parts named were drawn since the burst began.
    func since(_ parts: [String]) -> Int {
      parts.map { probe[$0] - before[$0, default: 0] }.reduce(0, +)
    }
    let rows = ["PanelRow parking", "PanelRow poi_food"]
    // What a frame draws: the comparison, wherever it is read, the panel and its rows.
    let read = ["POIPanel", "POIPanelNote", "POIPanelNoteLine"] + rows

    // A camera driven frame by frame from zoom 13 down to 11, each frame landing where the app
    // moved it, the note's floor crossed once at 12.
    for frame in 1...60 {
      let compared = since(read)
      try map.jump(to: CameraTarget(zoom: 13 - 2 * Double(frame) / 60))
      #expect(await MapWindow.until(2) { since(read) > compared }, "frame \(frame)")
    }
    _ = await MapWindow.until(0.3) { false }

    // The work happened: the zoom was compared on every frame, and the note was drawn as it flipped.
    #expect(map.state.camera.zoom < 12)
    #expect(since(read) >= 60)
    #expect(probe["POIPanelNoteLine"] >= 1, "the note was never drawn")
    // The panel, its rows and its note were drawn again once, as the comparison flipped.
    let redrawn = since(["POIPanel", "POIPanelNoteLine"] + rows)
    let flips = 1
    let drawn = read.map { ($0, since([$0])) }
    #expect(
      redrawn <= zoomThresholdBudget * flips,
      "the panel was drawn \(redrawn) times over 60 frames and \(flips) flip: \(drawn)")
    window.isHidden = true
    _ = host
  }

  @Test("a row per concept the map draws at the points of interest's rank, on while shown")
  func rows() throws {
    let map = try Self.drawing()
    map.setKeyVisibility("parking", visible: false)
    let offer = POIPanel(map: map).offer

    #expect(offer.rows.map(\.id) == ["parking", "poi_food"])
    #expect(offer.rows.map(\.isVisible) == [false, true])
    #expect(offer.isAnyVisible)
    #expect(POIPanel(map: nil).offer.rows.isEmpty, "a map drawing nothing offers no row")
  }

  @Test("a press shows or hides the row's keys on the map, unless a handler stands in for it")
  func toggles() throws {
    let map = try Self.drawing()
    let panel = POIPanel(map: map)
    let parking = try #require(panel.offer.rows.first)

    panel.toggle(parking, visible: false)
    #expect(!map.isKeyVisible("parking"))
    var handed: [String] = []
    POIPanel(map: map, onToggle: { key, visible in handed.append("\(key):\(visible)") })
      .toggle(parking, visible: true)
    #expect(handed == ["parking:true"])
    #expect(!map.isKeyVisible("parking"), "a handler stands in for the map")

    let water = POIPanel(
      map: map, groups: [POIPanelGroup(id: "eat", label: "Eat", keys: ["poi_food", "cafe"])],
      onToggleGroup: { id, visible in handed.append("group \(id):\(visible)") })
    let eat = try #require(water.offer.rows.first)
    #expect(eat.keys == ["poi_food"])
    water.toggle(eat, visible: false)
    #expect(handed.last == "group eat:false")
  }

  @Test("the master row shows or hides every row's keys, unless a handler stands in for it")
  func master() throws {
    let map = try Self.drawing()
    let panel = POIPanel(map: map, showsAllToggle: true)

    panel.toggleAll(false, rows: panel.offer.rows)
    #expect(!map.isKeyVisible("parking") && !map.isKeyVisible("poi_food"))
    #expect(!panel.offer.isAnyVisible)
    var all: [Bool] = []
    POIPanel(map: map, onToggleAll: { all.append($0) }).toggleAll(true, rows: panel.offer.rows)
    #expect(all == [true])
    #expect(!map.isKeyVisible("parking"))
  }

  @Test("the note stands below the overlay's floor zoom, never at it, and never with no floor")
  func note() {
    #expect(POIPanel.isNoted(zoom: 11.9, minZoom: 12))
    #expect(!POIPanel.isNoted(zoom: 12, minZoom: 12))
    #expect(!POIPanel.isNoted(zoom: 3, minZoom: .nan))
    #expect(!POIPanel.isNoted(zoom: 3, minZoom: nil))
    #expect(!POIPanel.isNoted(zoom: nil, minZoom: 12))
  }

  @Test("a map drawing no point of interest shows no panel at all")
  func nothing() throws {
    let empty = Controls.drawn(POIPanel(map: try Maps.engine()))
    #expect(empty == nil || empty?.size == .zero)
    #expect((Controls.drawn(POIPanel(map: try Self.drawing()))?.size.height ?? 0) > 44)
  }
}
