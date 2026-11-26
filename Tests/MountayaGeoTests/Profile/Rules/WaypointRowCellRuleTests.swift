import Foundation
import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("waypointRowCell")
struct WaypointRowCellRuleTests {
  private let english = UnitPreferences(language: "en")

  private func row(name: String? = "Refuge Elisabetta", glyph: RestSchema.WaypointIcon? = "hut")
    -> ItineraryWaypointRow
  {
    let details = WaypointDetails(
      amenities: ["water", "hot-meal"],
      timing: WaypointDetails.Timing(cutoffAt: Date(timeIntervalSince1970: 1_788_000_000)),
      properties: [
        WaypointDetails.Property(
          key: "next-water", label: "Next water", value: "3600", format: "distance"),
        WaypointDetails.Property(
          key: "page", label: "Page", value: " https://refuge.example ", format: "url"),
      ])
    return ItineraryWaypointRow(
      key: "refuge#0",
      place: ProfilePlace(
        .atDistance(id: "refuge", distance: 14_600), name: name, glyph: glyph, details: details),
      index: 3, from: 9_400, to: 14_600,
      metrics: ItineraryWaypointRowMetrics(
        distance: 14_600, sectionDistance: 5_200, ascent: 1_250, descent: 310, sectionAscent: 640,
        sectionDescent: 25, altitude: 2_102))
  }

  private func set(_ glyphs: String...) throws -> GlyphSet {
    try #require(
      GlyphSet(
        name: "held", paint: .stroke,
        markup: Dictionary(uniqueKeysWithValues: glyphs.map { ($0, "<path d=\"M0 0h1\"/>") })))
  }

  @Test("the default columns, and the figures of a place")
  func columns() throws {
    #expect(
      defaultWaypointTableColumns == [.waypoint, .profile, .distance, .elevation, .amenities])
    let held = try set("hut")
    let cell = { (column: WaypointTableColumn) in
      waypointRowCell(self.row(), column: column, glyphs: held, units: self.english)
    }
    #expect(cell(.waypoint) == .waypoint(glyph: "hut", name: "Refuge Elisabetta"))
    #expect(cell(.profile) == .profile(lit: ProfileRange(from: 9_400, to: 14_600)))
    #expect(cell(.distance) == .distance(total: 14_600))
    #expect(cell(.elevation) == .elevation(ascent: 640, descent: 25))
    #expect(cell(.altitude) == .altitude(2_102))
    #expect(cell(.amenities) == .amenities(["water", "hot-meal"]))
  }

  @Test("a glyph the set cannot draw, or none, is the pin, whether the set draws it or not")
  func glyph() throws {
    #expect(
      waypointRowCell(row(name: nil), column: .waypoint, glyphs: try set(), units: english)
        == .waypoint(glyph: "map-pin", name: nil))
    #expect(
      waypointRowCell(row(glyph: nil), column: .waypoint, glyphs: try set("hut"), units: english)
        == .waypoint(glyph: "map-pin", name: "Refuge Elisabetta"))
  }

  @Test("a cut-off only through the caller's formatter, fields by their format with their links")
  func formatted() throws {
    let held = try set("hut")
    #expect(
      waypointRowCell(row(), column: .cutoff, glyphs: held, units: english)
        == .cutoff(moment: nil))
    #expect(
      waypointRowCell(row(), column: .cutoff, glyphs: held, units: english) { _ in "12:30" }
        == .cutoff(moment: "12:30"))
    #expect(
      waypointRowCell(row(), column: .properties, glyphs: held, units: english)
        == .properties([
          WaypointField(key: "next-water", label: "Next water", value: "3.6 km"),
          WaypointField(
            key: "page", label: "Page", value: " https://refuge.example ",
            href: "https://refuge.example"),
        ]))
  }

  @Test("a place that states nothing states no service, cut-off or field")
  func nothing() throws {
    var bare = row()
    bare.place.details = nil
    let held = try set("hut")
    #expect(
      waypointRowCell(bare, column: .amenities, glyphs: held, units: english) == .amenities([]))
    #expect(
      waypointRowCell(bare, column: .properties, glyphs: held, units: english) == .properties([]))
    #expect(
      waypointRowCell(bare, column: .cutoff, glyphs: held, units: english) { _ in "12:30" }
        == .cutoff(moment: nil))
  }
}
