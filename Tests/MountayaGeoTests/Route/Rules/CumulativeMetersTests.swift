import Testing

@testable import MountayaGeo

@Suite("cumulativeMeters")
struct CumulativeMetersTests {
  private let route: [[Double]] = [
    [6.8652, 45.9237], [6.8752, 45.9287], [6.8852, 45.9337], [6.8952, 45.9387], [6.9052, 45.9437],
    [6.9152, 45.9487], [6.9271, 45.9682],
  ]

  @Test("each vertex stands at the great-circle distance along the line")
  func greatCircle() {
    #expect(
      areClose(
        cumulativeMeters(route),
        [
          0, 952.543779427426, 1_905.0309496519576, 2_857.4615076298287, 3_809.835450319783,
          4_762.152774680362, 7_117.508508284167,
        ], within: 1e-6))
    #expect(
      cumulativeMeters([[0, 0], [1, 0], [2, 0]])
        == [0, metersPerDegreeMeanSphere, 2 * metersPerDegreeMeanSphere])
  }

  @Test("a leg across the antimeridian is the short way round")
  func antimeridian() {
    #expect(
      areClose(
        cumulativeMeters([[179.9, -16.8], [-179.9, -16.8]]), [0, 21_289.81335773995], within: 1e-6))
  }

  /// A vertex that names no place keeps its index, standing at the distance of the last that did.
  @Test("a vertex that names no place is bridged")
  func bridged() {
    #expect(
      areClose(
        cumulativeMeters([[6, 45], [.nan, 45], [7, 46]]), [0, 0, 135_786.09062692837], within: 1e-6)
    )
    #expect(
      areClose(
        cumulativeMeters([[6], [6, 45], [7, 46]]), [0, 0, 135_786.09062692837], within: 1e-6))
    #expect(
      areClose(
        cumulativeMeters([[6, 45], [7, 46], [7, .infinity]]),
        [0, 135_786.09062692837, 135_786.09062692837], within: 1e-6))
  }

  @Test("an altitude is no part of the distance")
  func altitude() {
    #expect(
      cumulativeMeters([[6, 45], [7, 46]]) == cumulativeMeters([[6, 45, 400], [7, 46, 4_000]]))
  }

  @Test("a line of one vertex or none has no length")
  func noLength() {
    #expect(cumulativeMeters([[6, 45]]) == [0])
    #expect(cumulativeMeters([]) == [])
  }
}
