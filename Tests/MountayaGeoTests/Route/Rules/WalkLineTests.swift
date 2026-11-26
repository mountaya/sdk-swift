import Testing

@testable import MountayaGeo

@Suite("walkLine")
struct WalkLineTests {
  /// A leg's length is the difference of its longitudes, so the walk reads as plain arithmetic.
  private func unit(_ a: [Double], _ b: [Double]) -> Double { b[0] - a[0] }

  @Test("each leg is added from the start")
  func legs() {
    var told: [(Double, Int)] = []
    let end = walkLine([[0, 0], [2, 0], [5, 0]], from: 10, legLength: unit) { at, _, index in
      told.append((at, index))
    }
    #expect(end == 15)
    #expect(told.map(\.0) == [10, 12, 15])
    #expect(told.map(\.1) == [0, 1, 2])
  }

  @Test("a vertex that names no place is told as none, at the last distance, and bridged")
  func bridged() {
    var told: [(Double, Bool)] = []
    let end = walkLine([[.nan, 0], [1, 0], [4], [4, 0]], from: 0, legLength: unit) {
      at, vertex, _ in
      told.append((at, vertex != nil))
    }
    #expect(end == 3)
    #expect(told.map(\.0) == [0, 0, 0, 3])
    #expect(told.map(\.1) == [false, true, false, true])
  }

  @Test("a line with no leg ends where it starts")
  func noLeg() {
    #expect(walkLine([], from: 7, legLength: unit) == 7)
    #expect(walkLine([[1, 1]], from: 7, legLength: unit) == 7)
  }
}
