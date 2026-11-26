import Testing

@testable import MountayaGeo

@Suite("refusesMaxBounds")
struct RefusesMaxBoundsTests {
  @Test("a lock that encloses an area is not refused, drawn upside down included")
  func enclosesAnArea() {
    #expect(!refusesMaxBounds([5, 45, 7, 46]))
    #expect(!refusesMaxBounds([179.5, 45, 180.5, 46]))
    #expect(!refusesMaxBounds([-179.9999999999, 45, 179.9999999999, 46]))
    // Drawn upside down, a lock still has a height to divide by.
    #expect(!refusesMaxBounds([5, 46, 7, 45]))
  }

  /// An east edge west of the west edge is how a renderer reads a lock across the antimeridian.
  @Test("a lock written across the antimeridian is not refused for it")
  func acrossTheAntimeridian() {
    #expect(!refusesMaxBounds([170, 45, -170, 46]))
  }

  @Test("a lock whose edges are a whole number of turns apart is refused")
  func wholeTurns() {
    #expect(refusesMaxBounds([5, 45, 5, 46]))
    #expect(refusesMaxBounds([-180, 45, 180, 46]))
    #expect(refusesMaxBounds([-360, 45, 360, 46]))
    #expect(refusesMaxBounds([180, 45, -180, 46]))
  }

  @Test("a lock whose south and north edges are one parallel is refused")
  func oneParallel() {
    #expect(refusesMaxBounds([5, 45, 7, 45]))
  }

  @Test("a lock with an edge at no finite coordinate, or not four edges, is refused")
  func notFinite() {
    #expect(refusesMaxBounds([.nan, 45, 6, 46]))
    #expect(refusesMaxBounds([0, 0, .infinity, 10]))
    #expect(refusesMaxBounds([0, -.infinity, 1, 10]))
    #expect(refusesMaxBounds([5, 45, 7]))
    #expect(refusesMaxBounds([]))
  }
}
