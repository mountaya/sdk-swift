import MountayaGeo
import RendererSupport
import SwiftUI
import Testing

@testable import MountayaElements

@Suite("ItinerarySparkline")
@MainActor
struct ItinerarySparklineTests {
  private static let series = ItineraryDrawing(resolved: Itineraries.resolved, legs: nil).series
  private static let base = Controls.color("#dee2e6")

  /// drawn is the sparkline of the test itinerary, the stretch `lit` drawn in `color`.
  private static func drawn(lit: ProfileRange? = nil, color: String? = nil) throws -> UIImage {
    try #require(
      Controls.drawn(
        ItinerarySparkline(series: series, lit: lit, color: color).frame(width: 120, height: 24)))
  }

  @Test("the whole curve is drawn in the base token, the lit stretch over it in its colour")
  func drawn() throws {
    let firstHalf = ProfileRange(from: 0, to: Self.series.totalDistance / 2)
    let plain = try Self.drawn()
    let red = try Self.drawn(lit: firstHalf, color: "#e03131")
    let accent = try Self.drawn(lit: firstHalf)
    // Low in the area, a quarter and three quarters across.
    let left = CGPoint(x: 30, y: 21)
    let right = CGPoint(x: 90, y: 21)

    #expect(Pixels.pixel(plain, at: left)?.isNear(Self.base) == true)
    #expect(Pixels.pixel(plain, at: right)?.isNear(Self.base) == true)
    #expect(
      Pixels.pixel(red, at: right)?.isNear(Self.base) == true, "the stretch not lit is the base")
    #expect(Pixels.pixel(red, at: left)?.isNear(Self.base) == false, "the lit stretch is tinted")
    #expect(
      Pixels.pixel(red, at: left) != Pixels.pixel(accent, at: left),
      "in its colour, else the accent")
    #expect(Pixels.pixel(plain, at: CGPoint(x: 60, y: 1))?.alpha == 0, "nothing over the curve")
  }
}
