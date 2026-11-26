import MountayaGeo
import RendererSupport
import SwiftUI
import Testing

@testable import MountayaElements

@Suite("RenderProbe")
@MainActor
struct RenderProbeTests {
  @Test("a probe counts each report by its part, and answers none for a part never reported")
  func counts() {
    let probe = RenderProbe()
    probe.report("PanelRow Parking")
    probe.report("PanelRow Parking")
    probe.report("source trail")

    #expect(probe["PanelRow Parking"] == 2)
    #expect(probe["source trail"] == 1)
    #expect(probe["ProfileChart"] == 0)
    #expect(probe.counts == ["PanelRow Parking": 2, "source trail": 1])
  }

  /// An app installs none, so a report reads a nil value and builds no name.
  @Test("a view reports to the probe its environment holds, which no environment holds unless set")
  func environment() throws {
    let probe = RenderProbe()
    let row = PanelRow(label: "Parking", isChecked: true, action: {}) { EmptyView() }

    #expect(EnvironmentValues().renderProbe == nil)
    _ = try #require(Controls.drawn(row.environment(\.renderProbe, probe)))
    #expect(probe["PanelRow Parking"] >= 1)
  }

  @Test("the profile chart drawn last hands the probe its curves and its scrub")
  func chart() throws {
    let probe = RenderProbe()
    let curves = ProfileCurves()
    let drawing = ItineraryDrawing(resolved: Itineraries.resolved, legs: nil)
    let series = drawing.series
    let domain = profileDomain(series)
    var scrubbed: [Int?] = []
    let chart = ProfileChart(
      series: series, domain: domain, window: drawing.whole, painted: [],
      placement: placeOnCurve(
        series, geometry: drawing.geometry, domain: domain, window: drawing.whole, places: []),
      stacks: [], lit: nil, cursor: ProfileCursor(markerId: profileCursorMarkerId),
      tooltip: false, stretches: [], showsElevationAxis: false,
      units: UnitPreferences(language: "en"), formatCutoffAt: nil,
      onScrub: { scrubbed.append($0) }, onWaypointTap: nil, curves: curves)

    _ = try #require(
      Controls.drawn(chart.frame(width: 300, height: 150).environment(\.renderProbe, probe)))
    probe.scrub?(2)
    probe.scrub?(nil)

    #expect(probe.curves === curves)
    #expect(scrubbed == [2, nil])
  }
}
