import MountayaGeo
import RendererSupport
import SwiftUI
import Testing

@testable import MountayaElements

@Suite("ProfileCurves")
@MainActor
struct ProfileCurvesTests {
  private static let drawing = ItineraryDrawing(resolved: Itineraries.resolved, legs: nil)

  @Test("a curve is built once for its series, domain and window, and held while they stand")
  func heldWhileTheyStand() {
    let curves = ProfileCurves()
    let series = Self.drawing.series
    let domain = profileDomain(series)
    let first = curves.curve(series, domain: domain, window: Self.drawing.whole)
    let again = curves.curve(series, domain: domain, window: Self.drawing.whole)

    #expect(curves.built == 1)
    #expect(first == again)
    #expect(
      first.line
        == plotPath(
          profilePolyline(series, domain: domain, window: Self.drawing.whole),
          in: CGSize(width: profileViewBox, height: profileViewBox)))
  }

  @Test("another window or domain builds the curve again, and the new one is held")
  func builtAgain() {
    let curves = ProfileCurves()
    let series = Self.drawing.series
    let domain = profileDomain(series)
    let whole = curves.curve(series, domain: domain, window: Self.drawing.whole)
    let half = ProfileRange(from: 0, to: series.totalDistance / 2)
    let narrowed = curves.curve(series, domain: domain, window: half)
    _ = curves.curve(series, domain: domain, window: half)

    #expect(curves.built == 2)
    #expect(whole != narrowed)
    _ = curves.curve(
      series, domain: ElevationDomain(min: domain.min - 100, max: domain.max),
      window: half)
    #expect(curves.built == 3)
  }

  @Test("a layer's look is drawn once for each scale, and the store is let go with its chart")
  func drawnOnceAndReleased() {
    weak var released: ProfileCurves?
    do {
      let curves = ProfileCurves()
      released = curves
      let series = Self.drawing.series
      let gray = HexColor(hex: "#868e96")
      let layer = ProfileCurveLayer(
        curve: curves.curve(series, domain: profileDomain(series), window: Self.drawing.whole),
        stops: [], lit: nil, ticks: [], dividers: [], cutoffs: [],
        colors: ProfileCurveLayer.Colors(
          accent: HexColor(hex: "#1c7ed6"), grid: gray, litFill: gray, dropLine: gray,
          dimmed: gray),
        size: CGSize(width: 30, height: 20), curves: curves)

      let first = curves.drawn(layer, scale: 1)
      #expect(first.size == CGSize(width: 30, height: 20))
      #expect(curves.drawn(layer, scale: 1) === first, "the same look draws nothing again")
      #expect(curves.curveDrawn == 1)
      _ = curves.drawn(layer, scale: 2)
      #expect(curves.curveDrawn == 2, "another scale draws it again")
    }
    #expect(released == nil, "the image is held without the store holding itself")
  }

  @Test("a curve is stretched from the square over the chart, and two caches' curves are apart")
  func scaledAndApart() {
    let unit = Path(CGRect(x: 0, y: 0, width: 100, height: 50))
    let scaled = ProfileCurve.scaled(unit, to: CGSize(width: 300, height: 150))

    #expect(scaled.boundingRect == CGRect(x: 0, y: 0, width: 300, height: 75))
    let series = Self.drawing.series
    let first = ProfileCurves()
    let second = ProfileCurves()
    let one = first.curve(series, domain: profileDomain(series), window: Self.drawing.whole)
    let other = second.curve(series, domain: profileDomain(series), window: Self.drawing.whole)
    #expect(one != other, "a curve is its own build's")
  }
}
