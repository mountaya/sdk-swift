import MountayaGeo
import RendererSupport
import SwiftUI
import Testing

@testable import MountayaElements

@Suite("ProfileDistanceAxis")
@MainActor
struct ProfileDistanceAxisTests {
  /// divider is the place `id` named `name`, dividing the itinerary `x` units across the chart.
  private static func divider(_ id: String, name: String, x: Double) -> CurveDivider {
    CurveDivider(
      key: id, place: ProfilePlace(.atDistance(id: id, distance: x * 100), name: name),
      distance: x * 100, x: x, y: 50)
  }

  @Test("every name is drawn where the row has room for it")
  func roomy() {
    let dividers = [
      Self.divider("hut", name: "Refuge", x: 10), Self.divider("col", name: "Col", x: 50),
      Self.divider("spring", name: "Source", x: 90),
    ]

    #expect(
      ProfileDistanceAxis.shownNames(dividers, width: 600).map(\.key) == ["hut", "col", "spring"])
  }

  @Test("a name crowding its neighbour is left out, the first and the last always drawn")
  func crowded() {
    let dividers = [
      Self.divider("hut", name: "Refuge du Lac Blanc", x: 10),
      Self.divider("col", name: "Col des Montets", x: 14),
      Self.divider("spring", name: "Source", x: 90),
    ]

    #expect(ProfileDistanceAxis.shownNames(dividers, width: 300).map(\.key) == ["hut", "spring"])
    #expect(ProfileDistanceAxis.shownNames([], width: 300).isEmpty)
  }

  @Test("the row is as high as its stops over its names")
  func height() throws {
    let axis = try #require(
      Controls.drawn(
        ProfileDistanceAxis(
          totalDistance: 12_000, window: ProfileRange(from: 0, to: 12_000), dividers: [],
          units: UnitPreferences(language: "en")
        ).frame(width: 300)))

    #expect(axis.size == CGSize(width: 300, height: 32))
  }

  @Test("the row grows with the reader's text size, its names measured at the size drawn")
  func textSize() throws {
    let axis = ProfileDistanceAxis(
      totalDistance: 12_000, window: ProfileRange(from: 0, to: 12_000), dividers: [],
      units: UnitPreferences(language: "en")
    ).frame(width: 300)
    let large = try #require(
      Controls.drawn(axis.environment(\.dynamicTypeSize, .accessibility3)))
    let dividers = [
      Self.divider("hut", name: "Refuge", x: 10),
      Self.divider("col", name: "Col des Montets", x: 40),
      Self.divider("spring", name: "Source", x: 90),
    ]

    #expect(large.size.height > 32, "\(large.size)")
    #expect(
      ProfileDistanceAxis.shownNames(dividers, width: 300, size: .large).map(\.key)
        == ["hut", "col", "spring"])
    #expect(
      ProfileDistanceAxis.shownNames(dividers, width: 300, size: .accessibility5).map(\.key)
        == ["hut", "spring"], "a name that fits at the default size crowds at the largest")
  }
}
