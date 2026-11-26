import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("selectBoundary")
struct SelectBoundaryTests {
  private func boundary(_ name: String, bbox: Double...) -> RestSchema.Boundaries {
    RestSchema.Boundaries(bbox: bbox, name: name)
  }

  private var pyrenees: RestSchema.Boundaries { boundary("pyrenees", bbox: -1, 42, 3, 43) }
  private var alps: RestSchema.Boundaries { boundary("alps", bbox: 5, 44, 8, 47) }
  private var hawaii: RestSchema.Boundaries { boundary("hawaii", bbox: -161, 18, -154, 23) }

  @Test("the first boundary holding the center is the lock, else the first")
  func firstHolding() {
    #expect(selectBoundary([pyrenees, alps], center: [6.88, 45.85]) == alps)
    #expect(selectBoundary([pyrenees, alps], center: [0, 0]) == pyrenees)
    #expect(
      selectBoundary([alps, boundary("wider", bbox: 0, 40, 10, 50)], center: [6.88, 45.85]) == alps)
  }

  @Test("no boundary is no lock")
  func none() {
    #expect(selectBoundary([], center: [6.88, 45.85]) == nil)
    #expect(selectBoundary([], center: [.nan, 45]) == nil)
  }

  @Test("a center is read as an angle, however many turns it is written away")
  func angle() {
    #expect(selectBoundary([alps, hawaii], center: [202.5, 21.3]) == hawaii)
    #expect(selectBoundary([hawaii, alps], center: [-353.12, 45.85]) == alps)
    let alpsATurnOut = boundary("alps", bbox: 365, 44, 368, 47)
    #expect(selectBoundary([hawaii, alpsATurnOut], center: [6.88, 45.85]) == alpsATurnOut)
  }

  @Test("a box across the antimeridian holds a center written on either side")
  func acrossTheAntimeridian() {
    let fiji = boundary("fiji", bbox: 177, -19, 182, -16)
    let fijiFromTheWest = boundary("fiji", bbox: -185, -19, -175, -16)
    #expect(selectBoundary([alps, fiji], center: [-179.5, -17]) == fiji)
    #expect(selectBoundary([alps, fiji], center: [180.5, -17]) == fiji)
    #expect(selectBoundary([alps, fijiFromTheWest], center: [182, -17]) == fijiFromTheWest)
    #expect(selectBoundary([alps, fijiFromTheWest], center: [170, -17]) == alps)
  }

  @Test("a center on an edge is inside, and one outside the latitudes is not")
  func edges() {
    let alpsToTheEdge = boundary("alps", bbox: 5, 44, 7.1, 47)
    let origin = boundary("origin", bbox: 0, 0, 1, 1)
    #expect(selectBoundary([pyrenees, alpsToTheEdge], center: [7.1, 47]) == alpsToTheEdge)
    #expect(selectBoundary([pyrenees, alpsToTheEdge], center: [5, 44]) == alpsToTheEdge)
    #expect(
      selectBoundary([origin, boundary("fiji", bbox: 175, -19, 185, -16)], center: [178, 40])
        == origin)
  }

  /// A box a turn or more wide holds every meridian between its latitudes.
  @Test("a box a turn wide holds every meridian")
  func turnWide() {
    let band = boundary("band", bbox: -180, -10, 180, 10)
    #expect(selectBoundary([alps, band], center: [-179, 0]) == band)
    #expect(selectBoundary([alps, band], center: [900, 0]) == band)
  }

  @Test("a center that names no place is held by no box")
  func noPlace() {
    #expect(selectBoundary([hawaii, alps], center: [.nan, 45]) == hawaii)
    #expect(selectBoundary([hawaii, alps], center: [.infinity, 45]) == hawaii)
    #expect(selectBoundary([hawaii, alps], center: [6.88]) == hawaii)
  }

  /// Such a box is not one the wire writes, and nothing is guessed about it.
  @Test("a box that is not four numbers, or is drawn backwards or upside down, holds nothing")
  func malformed() {
    let short = boundary("short", bbox: 5, 44, 8)
    let backwards = boundary("backwards", bbox: 8, 44, 5, 47)
    let upsideDown = boundary("upside-down", bbox: 5, 47, 8, 44)
    #expect(selectBoundary([short, alps], center: [6.88, 45.85]) == alps)
    #expect(selectBoundary([backwards, alps], center: [6.88, 45.85]) == alps)
    #expect(selectBoundary([upsideDown, alps], center: [6.88, 45.85]) == alps)
    #expect(selectBoundary([short, backwards, upsideDown], center: [6.88, 45.85]) == short)
  }
}
