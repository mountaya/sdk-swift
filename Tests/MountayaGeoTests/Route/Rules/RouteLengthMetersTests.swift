import Testing

@testable import MountayaGeo

@Suite("routeLengthMeters")
struct RouteLengthMetersTests {
  @Test("the length is the sum of the great-circle legs, a vertex that names no place bridged")
  func sum() {
    #expect(routeLengthMeters([[0, 0], [1, 0], [2, 0]]) == 2 * metersPerDegreeMeanSphere)
    #expect(
      isClose(
        routeLengthMeters([[6, 45], [.nan, 45], [7, 46]]), 135_786.09062692837, within: 1e-6))
  }

  @Test("a line of one vertex or none has no length")
  func noLength() {
    #expect(routeLengthMeters([[6, 45]]) == 0)
    #expect(routeLengthMeters([]) == 0)
    #expect(routeLengthMeters([[6], [.nan, 45]]) == 0)
  }
}
