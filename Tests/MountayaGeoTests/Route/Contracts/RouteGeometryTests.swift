import Testing

@testable import MountayaGeo

@Suite("RouteGeometry")
struct RouteGeometryTests {
  private func route() -> RouteGeometry {
    RouteGeometry(
      line: [[6, 45], [6.1, 45.1], [6.2, 45.2]], elevations: [1_000, 1_100, 1_200], jumps: [2])
  }

  @Test("a fresh copy is the same route, and hashes alike")
  func freshCopy() {
    #expect(route() == route())
    #expect(route().hashValue == route().hashValue)
  }

  @Test("an edited route is another")
  func edited() {
    let first = route()
    #expect(
      first
        != RouteGeometry(
          line: [[6, 45], [6.11, 45.1], [6.2, 45.2]], elevations: first.elevations,
          jumps: first.jumps))
    #expect(
      first
        != RouteGeometry(
          line: first.line + [[6.3, 45.3]], elevations: first.elevations + [1_300],
          jumps: first.jumps))
    #expect(
      first
        != RouteGeometry(line: first.line, elevations: [1_000, 1_150, 1_200], jumps: first.jumps))
    #expect(first != RouteGeometry(line: first.line, jumps: first.jumps))
    #expect(first != RouteGeometry(line: first.line, elevations: first.elevations, jumps: [1]))
  }

  @Test("no list is an empty one")
  func noList() {
    let line: [[Double]] = [[6, 45], [6.1, 45.1]]
    #expect(RouteGeometry(line: line, jumps: []) == RouteGeometry(line: line))
    #expect(RouteGeometry(line: line, elevations: []) == RouteGeometry(line: line))
  }

  @Test("each value is compared as the same number")
  func sameNumbers() {
    let unplaced: [[Double]] = [[6, 45], [.nan, 45.1]]
    #expect(RouteGeometry(line: unplaced) == RouteGeometry(line: unplaced.map { Array($0) }))
    #expect(
      RouteGeometry(line: unplaced).hashValue
        == RouteGeometry(line: unplaced.map { Array($0) }).hashValue)
    #expect(RouteGeometry(line: [[0, 45]]) != RouteGeometry(line: [[-0.0, 45]]))
    #expect(RouteGeometry(line: [[6, 45]]) != RouteGeometry(line: [[6, 45, 1_000]]))
    #expect(
      RouteGeometry(line: [[6, 45]], elevations: [.nan])
        == RouteGeometry(line: [[6, 45]], elevations: [.nan]))
  }

  @Test("the route is written line first")
  func description() {
    #expect(
      String(describing: route())
        == "RouteGeometry(line: [[6.0, 45.0], [6.1, 45.1], [6.2, 45.2]], "
        + "elevations: [1000.0, 1100.0, 1200.0], jumps: [2])")
  }
}
