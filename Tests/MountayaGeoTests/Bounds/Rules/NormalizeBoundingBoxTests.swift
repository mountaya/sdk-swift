import Testing

@testable import MountayaGeo

@Suite("normalizeBoundingBox")
struct NormalizeBoundingBoxTests {
  @Test("a canonical box is answered as it is")
  func canonical() {
    #expect(normalizeBoundingBox([6.86, 45.8, 6.9, 45.92]) == [6.86, 45.8, 6.9, 45.92])
  }

  /// A west edge greater than the east one is a box drawn from its east corner, never one across
  /// the antimeridian: that box is written with its east edge past 180.
  @Test("each axis is ordered low to high")
  func ordered() {
    #expect(normalizeBoundingBox([6.9, 45.92, 6.86, 45.8]) == [6.86, 45.8, 6.9, 45.92])
    #expect(normalizeBoundingBox([170, 45, -170, 46]) == [-170, 45, 170, 46])
  }

  @Test("the west edge is brought within one world, and the east edge follows")
  func westEdge() {
    #expect(normalizeBoundingBox([179.5, -17, 180.5, -16]) == [179.5, -17, 180.5, -16])
    #expect(normalizeBoundingBox([-180.5, -17, -179.5, -16]) == [179.5, -17, 180.5, -16])
    #expect(normalizeBoundingBox([365, 0, 367, 1]) == [5, 0, 7, 1])
  }

  @Test("a turn or more wide is the whole world")
  func turnWide() {
    #expect(normalizeBoundingBox([-200, 0, 200, 10]) == [-180, 0, 180, 10])
    #expect(normalizeBoundingBox([0, 0, 360, 10]) == [-180, 0, 180, 10])
    #expect(normalizeBoundingBox([-.infinity, 0, 5, 10]) == [-180, 0, 180, 10])
  }

  @Test("the latitudes are held within the Web Mercator limit, each on its own")
  func latitudes() {
    #expect(normalizeBoundingBox([-10, -89, 10, 89]) == [-10, -85.051129, 10, 85.051129])
    #expect(normalizeBoundingBox([-10, 86, 10, 89]) == [-10, 85.051129, 10, 85.051129])
  }

  @Test("nothing is refused")
  func nothingRefused() {
    #expect(sameNumbers(normalizeBoundingBox([.nan, 45, 6, 46]), [.nan, 45, .nan, 46]))
    #expect(
      sameNumbers(normalizeBoundingBox([.infinity, 45, .infinity, 46]), [.nan, 45, .nan, 46]))
    #expect(sameNumbers(normalizeBoundingBox([5, .nan, 6, 46]), [5, .nan, 6, .nan]))
  }

  @Test("a box that is not four numbers is no box")
  func notFour() {
    let none: [Double] = [.nan, .nan, .nan, .nan]
    #expect(sameNumbers(normalizeBoundingBox([]), none))
    #expect(sameNumbers(normalizeBoundingBox([6, 45, 7]), none))
    #expect(sameNumbers(normalizeBoundingBox([6, 45, 0, 7, 46, 1000]), none))
  }
}
