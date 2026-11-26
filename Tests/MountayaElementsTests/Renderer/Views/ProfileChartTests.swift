import MountayaClient
import MountayaGeo
import RendererSupport
import SwiftUI
import Testing

@testable import MountayaElements

@Suite("ProfileChart")
@MainActor
struct ProfileChartTests {
  private static let drawing = ItineraryDrawing(resolved: Itineraries.resolved, legs: nil)
  private static let size = CGSize(width: 300, height: 150)
  private static let accent = Controls.color("#1c7ed6")
  private static let english = UnitPreferences(language: "en")

  /// move stands `cursor` on sample `index` of the test itinerary, or on none, writing no map.
  private static func move(_ cursor: ProfileCursor, to index: Int?) {
    cursor.point(
      at: index, value: nil, target: MapTarget(), isEnabled: true, onHover: nil, map: nil,
      markerColor: nil, emphasisColor: nil)
  }

  /// standing is a cursor standing on sample `index` of the test itinerary, or on none.
  private static func standing(_ index: Int?) -> ProfileCursor {
    let cursor = ProfileCursor(markerId: profileCursorMarkerId)
    move(cursor, to: index)
    return cursor
  }

  /// chart is the test itinerary's chart over its whole window: its places pinned where `places`,
  /// the stretch `lit` tinted, its cursor `cursor`, and its card where `tooltip`.
  private static func chart(
    places: Bool = true, lit: ProfileRange? = nil, cursor: ProfileCursor? = nil,
    tooltip: Bool = false, curves: ProfileCurves = ProfileCurves(),
    onWaypointTap: ((String) -> Void)? = nil
  ) -> some View {
    let series = drawing.series
    let domain = profileDomain(series)
    let placement = placeOnCurve(
      series, geometry: drawing.geometry, domain: domain, window: drawing.whole,
      places: places ? drawing.places : [])
    return ProfileChart(
      series: series, domain: domain, window: drawing.whole, painted: [], placement: placement,
      stacks: amenityStacks(placement.pins), lit: lit, cursor: cursor ?? standing(nil),
      tooltip: tooltip, stretches: [], showsElevationAxis: false, units: english,
      formatCutoffAt: nil, onScrub: { _ in }, onWaypointTap: onWaypointTap, curves: curves
    )
    .frame(width: size.width, height: size.height)
  }

  /// ScrubHost hosts the test itinerary's chart over curves the test holds, its cursor where the
  /// test stands it.
  fileprivate struct ScrubHost: View {
    let cursor: ProfileCursor
    let curves: ProfileCurves

    var body: some View {
      ProfileChartTests.chart(places: false, cursor: cursor, curves: curves)
    }
  }

  @Test("the curve and the area under it are drawn where the scale places them, in the accent")
  func curve() throws {
    let image = try #require(Controls.drawn(Self.chart(places: false)))
    let line = profilePolyline(Self.drawing.series, domain: profileDomain(Self.drawing.series))
    let start = plotPoint(line[0], in: Self.size)
    let next = plotPoint(line[1], in: Self.size)
    let between = CGPoint(x: (start.x + next.x) / 2, y: (start.y + next.y) / 2)
    let shaded = try #require(Pixels.pixel(image, at: CGPoint(x: between.x, y: 138)))

    #expect(Pixels.pixel(image, at: between)?.isNear(Self.accent) == true)
    #expect(abs(shaded.alpha - 46) <= 8, "the area at 0.18 of the accent: \(shaded)")
    #expect(
      Pixels.Pixel(red: shaded.red, green: shaded.green, blue: shaded.blue, alpha: 255)
        .isNear(Self.accent, tolerance: 16))
    #expect(Pixels.pixel(image, at: CGPoint(x: between.x, y: 2))?.alpha == 0, "nothing above it")
  }

  @Test("the leg a reader points at is tinted under the curve, and only there")
  func lit() throws {
    let climb = Self.drawing.rows[0]
    let plain = try #require(Controls.drawn(Self.chart(places: false)))
    let tinted = try #require(
      Controls.drawn(Self.chart(places: false, lit: ProfileRange(from: climb.from, to: climb.to))))
    let left = CGPoint(x: 40, y: 138)
    let right = CGPoint(x: 260, y: 138)

    #expect(Pixels.pixel(tinted, at: left) != Pixels.pixel(plain, at: left))
    let rightPlain = try #require(Pixels.pixel(plain, at: right))
    #expect(Pixels.pixel(tinted, at: right)?.isNear(rightPlain, tolerance: 2) == true)
  }

  @Test(
    "a pin stands on the curve at each place, in the profile's colour where the place names none")
  func pins() throws {
    let image = try #require(Controls.drawn(Self.chart()))
    let series = Self.drawing.series
    let placement = placeOnCurve(
      series, geometry: Self.drawing.geometry, domain: profileDomain(series),
      window: Self.drawing.whole, places: Self.drawing.places)

    #expect(placement.pins.map(\.place.id) == ["hut", "col", "spring"])
    // The col stands at the summit, its pin above the chart's top edge, drawn over what is above.
    for pin in placement.pins where pin.place.id != "col" {
      let centre = CGPoint(
        x: pin.x / profileViewBox * Self.size.width,
        y: pin.y / profileViewBox * Self.size.height - ProfileChart.pinSide / 2)
      let face = CGPoint(x: centre.x + 7, y: centre.y)
      #expect(
        Pixels.pixel(image, at: face)?.isNear(Controls.color("#868e96")) == true,
        "\(pin.place.id): \(String(describing: Pixels.pixel(image, at: face)))")
    }
  }

  @Test("the cursor's rule crosses the chart at its sample, and its card stands beside it")
  func cursor() throws {
    let points = Self.drawing.series.points
    let none = try #require(Controls.drawn(Self.chart(places: false)))
    let shown = try #require(
      Controls.drawn(Self.chart(places: false, cursor: Self.standing(1), tooltip: true)))
    let x =
      profileX(points[1].distance, totalDistance: Self.drawing.series.totalDistance)
      / profileViewBox * Self.size.width
    let column = stride(from: 1.0, to: 20.0, by: 0.5).map { CGPoint(x: x, y: $0) }

    #expect(
      column.compactMap { Pixels.pixel(shown, at: $0) }
        .contains { $0.isNear(Controls.color("#212529")) }, "the dashed rule above the curve")
    #expect(column.compactMap { Pixels.pixel(none, at: $0) }.allSatisfy { $0.alpha == 0 })
    // The card stands 70 points after the cursor, on the side with room, on the tooltip's ground.
    #expect(Pixels.pixel(shown, at: CGPoint(x: x + 70, y: 36))?.alpha == 255)
    #expect(Pixels.pixel(none, at: CGPoint(x: x + 70, y: 36))?.alpha != 255)
  }

  @Test("a scrub draws the cursor's layer alone, the curve built once and drawn no more")
  func scrubDrawsTheCursorAlone() async throws {
    let curves = ProfileCurves()
    let cursor = Self.standing(nil)
    let (host, window) = Hosted.showing(ScrubHost(cursor: cursor, curves: curves))
    #expect(await MapWindow.until { curves.curveDrawn >= 1 && curves.cursorDrawn >= 1 })
    _ = await MapWindow.until(0.3) { false }
    let curveDrawn = curves.curveDrawn

    // Samples 2 and 3 are the col, where the climb ends and the descent starts, at one place: the
    // cursor moves across the others.
    for index in [1, 2, 4, 5] {
      let before = curves.cursorDrawn
      Self.move(cursor, to: index)
      #expect(await MapWindow.until { curves.cursorDrawn > before }, "sample \(index)")
    }
    Self.move(cursor, to: nil)
    _ = await MapWindow.until(0.3) { false }

    #expect(curves.built == 1, "the curve is built once for its series, domain and window")
    let drawn = (curve: curves.curveDrawn, cursor: curves.cursorDrawn)
    #expect(
      curves.curveDrawn == curveDrawn, "a scrub draws the curve no more: \(drawn), \(curveDrawn)")
    window.isHidden = true
    _ = host
  }

  @Test("a scrub changes nothing the curve's layer takes, so SwiftUI holds it as drawn")
  func curveLayerEquality() {
    let curves = ProfileCurves()
    let series = Self.drawing.series
    let curve = curves.curve(series, domain: profileDomain(series), window: Self.drawing.whole)
    let gray = HexColor(hex: "#868e96")
    let colors = ProfileCurveLayer.Colors(
      accent: HexColor(hex: "#1c7ed6"), grid: gray, litFill: HexColor(hex: "#ffd43b"),
      dropLine: gray, dimmed: gray)
    func layer(lit: ClosedRange<Double>? = nil) -> ProfileCurveLayer {
      ProfileCurveLayer(
        curve: curve, stops: [], lit: lit, ticks: [], dividers: [], cutoffs: [], colors: colors,
        size: Self.size, curves: curves)
    }

    #expect(layer() == layer())
    #expect(layer() != layer(lit: 10...20), "a leg lit draws it again")
  }

  @Test("a pin a reader can press is pressed in the touch target, its disc kept 20 points across")
  func pinTargets() throws {
    let series = Self.drawing.series
    let placement = placeOnCurve(
      series, geometry: Self.drawing.geometry, domain: profileDomain(series),
      window: Self.drawing.whole, places: Self.drawing.places)
    let pin = try #require(placement.pins.first)
    let pressable = try #require(
      Controls.drawn(ProfilePin(pin: pin, fill: .red, name: "Hut", onTap: {})))
    let still = try #require(
      Controls.drawn(ProfilePin(pin: pin, fill: .red, name: "Hut", onTap: nil)))

    #expect(pressable.size == CGSize(width: 44, height: 44))
    #expect(still.size == CGSize(width: ProfileChart.pinSide, height: ProfileChart.pinSide))
    #expect(Pixels.pixel(pressable, at: CGPoint(x: 22, y: 15))?.alpha == 255, "the disc, centred")
    #expect(Pixels.pixel(pressable, at: CGPoint(x: 4, y: 4))?.alpha == 0)
  }

  @Test("a pointer reads the sample its column stands for, held to the chart's two ends")
  func sample() {
    let grid = scrubGrid(Self.drawing.series.points, window: Self.drawing.whole)

    #expect(ProfileChart.sample(at: 0, width: 300, grid: grid) == 0)
    #expect(ProfileChart.sample(at: 75, width: 300, grid: grid) == 1)
    #expect(ProfileChart.sample(at: 300, width: 300, grid: grid) == 5)
    #expect(ProfileChart.sample(at: -20, width: 300, grid: grid) == 0)
    #expect(ProfileChart.sample(at: 900, width: 300, grid: grid) == 5)
    #expect(ProfileChart.sample(at: 10, width: 0, grid: grid) == nil)
    #expect(ProfileChart.sample(at: 10, width: 300, grid: []) == nil)
  }

  @Test("the card labels each figure with its word and writes it in the reader's units")
  func readout() {
    #expect(ProfileReadoutCard.word(.distance) == "profile.distance")
    #expect(ProfileReadoutCard.word(.elevation) == "profile.elevation")
    #expect(
      ProfileReadoutCard.value(ReadoutCell(stat: .elevation, value: 1_200), units: Self.english)
        == "1,200 m")
    #expect(
      ProfileReadoutCard.value(ReadoutCell(stat: .distance, value: 2_224), units: Self.english)
        == "2.2 km")
    #expect(
      ProfileReadoutCard.value(
        ReadoutCell(stat: .ascent, value: 400),
        units: UnitPreferences(language: "en", length: .imperial)) == "1,312 ft")
  }
}
