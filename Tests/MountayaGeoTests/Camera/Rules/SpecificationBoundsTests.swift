import Testing

@testable import MountayaGeo

@Suite("specificationBounds")
struct SpecificationBoundsTests {
  @Test("a box is answered as written, and one across the antimeridian with its east edge past 180")
  func boxes() {
    #expect(specificationBounds([5.9, 45.8, 10.5, 47.8]) == [5.9, 45.8, 10.5, 47.8])
    let across = specificationBounds([179.8, -17, -179.9, -16])
    #expect(across?.count == 4)
    #expect(abs((across?[2] ?? 0) - 180.1) < 1e-9, "\(String(describing: across))")
    #expect(across?[0] == 179.8)
    // A box of one meridian is no box across the antimeridian.
    #expect(specificationBounds([6.86, 45.8, 6.86, 45.9]) == [6.86, 45.8, 6.86, 45.9])
  }

  @Test("no box, or a box that is not four numbers, frames nothing")
  func noBox() {
    #expect(specificationBounds(nil) == nil)
    #expect(specificationBounds([5.9, 45.8, 10.5]) == nil)
    #expect(specificationBounds([]) == nil)
  }
}
