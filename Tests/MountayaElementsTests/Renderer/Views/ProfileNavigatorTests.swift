import MountayaGeo
import RendererSupport
import SwiftUI
import Testing

@testable import MountayaElements

@Suite("ProfileNavigator")
@MainActor
struct ProfileNavigatorTests {
  private static let total = 10_000.0
  private static let whole = ProfileRange(from: 0, to: total)
  private static let window = ProfileRange(from: 2_000, to: 6_000)

  @Test("a drag grabs the handle within reach of it, else the whole window")
  func part() {
    #expect(ProfileNavigator.part(at: 70, start: 60, end: 180) == .start)
    #expect(ProfileNavigator.part(at: 200, start: 60, end: 180) == .end)
    #expect(ProfileNavigator.part(at: 120, start: 60, end: 180) == .whole)
  }

  @Test("a handle moves its end to the distance the column under it stands for, never to a sample")
  func handle() {
    let start = ProfileNavigator.Grab(part: .start, window: Self.window)

    // Column 24 of 240 on a strip 240 points wide: 24.5 / 240 of the itinerary.
    #expect(
      ProfileNavigator.moved(start, from: 60, to: 24, width: 240, total: Self.total)
        == ProfileRange(from: scrubDistance(column: 24, window: Self.whole), to: 6_000))
  }

  @Test("a handle dragged past the strip stops at its last column, and past its partner swaps")
  func past() {
    let end = ProfileNavigator.Grab(part: .end, window: Self.window)

    #expect(
      ProfileNavigator.moved(end, from: 144, to: 900, width: 240, total: Self.total)
        == ProfileRange(from: 2_000, to: scrubDistance(column: 239, window: Self.whole)))
    #expect(
      ProfileNavigator.moved(end, from: 144, to: 24, width: 240, total: Self.total)
        == ProfileRange(from: scrubDistance(column: 24, window: Self.whole), to: 2_000))
  }

  @Test("the window dragged whole keeps its span and stays inside the itinerary")
  func whole() {
    let grab = ProfileNavigator.Grab(part: .whole, window: Self.window)

    #expect(
      ProfileNavigator.moved(grab, from: 100, to: 124, width: 240, total: Self.total)
        == ProfileRange(from: 3_000, to: 7_000))
    #expect(
      ProfileNavigator.moved(grab, from: 100, to: 400, width: 240, total: Self.total)
        == ProfileRange(from: 6_000, to: 10_000))
    #expect(
      ProfileNavigator.moved(grab, from: 100, to: -300, width: 240, total: Self.total)
        == ProfileRange(from: 0, to: 4_000))
  }

  @Test("a window narrower than the narrowest is widened, and a strip of no width moves nothing")
  func narrow() {
    let end = ProfileNavigator.Grab(part: .end, window: Self.window)

    #expect(
      ProfileNavigator.moved(end, from: 144, to: 48, width: 240, total: Self.total)
        == ProfileRange(from: 2_000, to: 2_100))
    #expect(
      ProfileNavigator.moved(end, from: 0, to: 100, width: 0, total: Self.total) == Self.window)
  }

  @Test("the itinerary outside the window is veiled, and the window is not")
  func veiled() throws {
    let series = ItineraryDrawing(resolved: Itineraries.resolved, legs: nil).series
    let total = series.totalDistance
    let drawn = { (window: ProfileRange) throws -> UIImage in
      try #require(
        Controls.drawn(
          ProfileNavigator(
            series: series, domain: profileDomain(series), window: window, onChange: { _ in }
          ).frame(width: 300)))
    }
    let open = try drawn(ProfileRange(from: 0, to: total))
    let narrowed = try drawn(ProfileRange(from: total / 3, to: total * 2 / 3))
    let outside = CGPoint(x: 30, y: 33)
    let inside = CGPoint(x: 150, y: 33)

    #expect(open.size.height == 36)
    #expect(Pixels.pixel(narrowed, at: outside) != Pixels.pixel(open, at: outside))
    let shown = try #require(Pixels.pixel(open, at: inside))
    #expect(Pixels.pixel(narrowed, at: inside)?.isNear(shown, tolerance: 2) == true)
  }
}
