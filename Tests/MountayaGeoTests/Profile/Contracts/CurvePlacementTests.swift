import Testing

@testable import MountayaGeo

@Suite("CurvePlacement")
struct CurvePlacementTests {
  @Test("a placement holds its pins, dividers and cut-offs as given")
  func members() {
    let col = ProfilePlace(.atDistance(id: "col", distance: 250), name: "Col")
    let pin = CurvePin(key: "col#0", place: col, distance: 250, x: 50, y: 51, altitude: 1_250)
    let divider = CurveDivider(key: "col#0", place: col, distance: 250, x: 50, y: 51)
    let placement = CurvePlacement(pins: [pin], dividers: [divider], cutoffs: [])
    #expect(placement.pins == [pin] && placement.dividers == [divider] && placement.cutoffs.isEmpty)
    #expect(placement == CurvePlacement(pins: [pin], dividers: [divider], cutoffs: []))
  }
}
