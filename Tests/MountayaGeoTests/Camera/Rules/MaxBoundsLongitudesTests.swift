import Testing

@testable import MountayaGeo

@Suite("maxBoundsLongitudes")
struct MaxBoundsLongitudesTests {
  /// edges tells whether a lock's two edges are the expected ones, finer than the hair, so an
  /// answer a whole turn wide fails.
  private func edges(_ actual: [Double], _ expected: [Double]) -> Bool {
    areClose(actual, expected, within: 1e-11)
  }

  @Test("a lock narrower than a turn keeps its width")
  func narrower() {
    #expect(maxBoundsLongitudes(west: 5, east: 7) == [5, 7])
    #expect(maxBoundsLongitudes(west: 179.5, east: 180.5) == [179.5, 180.5])
    #expect(maxBoundsLongitudes(west: -179.5, east: 180) == [-179.5, 180])
  }

  @Test("its west edge is brought within one world, and its east edge follows")
  func westEdge() {
    #expect(maxBoundsLongitudes(west: 365, east: 367) == [5, 7])
    #expect(maxBoundsLongitudes(west: -180.5, east: -179.5) == [179.5, 180.5])
  }

  /// A renderer reads a pair written east first as a lock across the antimeridian.
  @Test("edges written east first are never reordered")
  func eastFirst() {
    #expect(maxBoundsLongitudes(west: 170, east: -170) == [170, -170])
  }

  @Test("a lock a turn or more wide is the whole world a hair under a turn, around its centre")
  func turnWide() {
    #expect(edges(maxBoundsLongitudes(west: -180, east: 180), [-179.9999999999, 179.9999999999]))
    #expect(edges(maxBoundsLongitudes(west: -200, east: 200), [-179.9999999999, 179.9999999999]))
    #expect(edges(maxBoundsLongitudes(west: 0, east: 360), [1e-10, 359.9999999999]))
    #expect(
      edges(
        maxBoundsLongitudes(west: 10_000_000, east: 10_000_400), [-59.9999999999, 299.9999999999]))
    let world = maxBoundsLongitudes(west: -180, east: 180)
    #expect(world[1] - world[0] < 360)
    #expect(isClose(worldLockHalfSpanDegrees, 179.9999999999, within: 1e-12))
  }

  @Test("a lock reaching an infinity is the whole world on the prime meridian")
  func infinity() {
    let world = [-179.9999999999, 179.9999999999]
    #expect(edges(maxBoundsLongitudes(west: -.infinity, east: 5), world))
    #expect(edges(maxBoundsLongitudes(west: 5, east: .infinity), world))
    #expect(edges(maxBoundsLongitudes(west: -.infinity, east: .infinity), world))
  }

  @Test("an edge at no number places the lock nowhere")
  func nowhere() {
    let nowhere: [Double] = [.nan, .nan]
    #expect(sameNumbers(maxBoundsLongitudes(west: .nan, east: 5), nowhere))
    #expect(sameNumbers(maxBoundsLongitudes(west: 5, east: .nan), nowhere))
    #expect(sameNumbers(maxBoundsLongitudes(west: .infinity, east: 5), nowhere))
    #expect(sameNumbers(maxBoundsLongitudes(west: .infinity, east: .infinity), nowhere))
    #expect(sameNumbers(maxBoundsLongitudes(west: 5, east: -.infinity), nowhere))
  }
}
