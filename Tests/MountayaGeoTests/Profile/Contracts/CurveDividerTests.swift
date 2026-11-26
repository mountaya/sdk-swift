import Testing

@testable import MountayaGeo

@Suite("CurveDivider")
struct CurveDividerTests {
  @Test("a divider is named as its place is, and empty for a place with no name")
  func name() {
    let col = ProfilePlace(.atDistance(id: "col", distance: 250), name: "Col")
    let marker = ProfilePlace(.atDistance(id: "marker", distance: 350), divides: true)
    #expect(CurveDivider(key: "col#0", place: col, distance: 250, x: 50, y: 51).name == "Col")
    #expect(CurveDivider(key: "marker#0", place: marker, distance: 350, x: 70, y: nil).name == "")
  }

  @Test("two dividers are equal where every member is the same, a missing height only to another")
  func equality() {
    let col = ProfilePlace(.atDistance(id: "col", distance: 250), name: "Col")
    #expect(
      CurveDivider(key: "col#0", place: col, distance: 250, x: 50, y: nil)
        == CurveDivider(key: "col#0", place: col, distance: 250, x: 50, y: nil))
    #expect(
      CurveDivider(key: "col#0", place: col, distance: 250, x: 50, y: nil)
        != CurveDivider(key: "col#0", place: col, distance: 250, x: 50, y: 51))
  }
}
