import Testing

@testable import MountayaGeo

@Suite("stretchAt")
struct StretchAtTests {
  private let gap = [
    ProfileClass(from: 0, to: 500, color: "#2f9e44", label: "Path"),
    ProfileClass(from: 800, to: 1_200, color: "#e8590c", label: "Trail"),
  ]

  @Test("a distance inside or at the start of a stretch reads it")
  func inside() {
    #expect(stretchAt(gap, distance: 250)?.label == "Path")
    #expect(stretchAt(gap, distance: 800)?.label == "Trail")
  }

  @Test("the last meter before a gap and of the itinerary keeps its stretch, a gap reads none")
  func ends() {
    #expect(stretchAt(gap, distance: 500)?.label == "Path")
    #expect(stretchAt(gap, distance: 1_200)?.label == "Trail")
    #expect(stretchAt(gap, distance: 600) == nil)
    #expect(stretchAt(gap, distance: -10) == nil)
    #expect(stretchAt(gap, distance: 1_300) == nil)
    #expect(stretchAt(gap, distance: .nan) == nil)
  }

  @Test("a boundary two stretches share reads the later, whatever the order given")
  func shared() {
    let touching = [
      ProfileRange(from: 500, to: 1_000), ProfileRange(from: 0, to: 500),
      ProfileRange(from: 500, to: 500),
    ]
    #expect(stretchAt(touching, distance: 500) == ProfileRange(from: 500, to: 1_000))
  }

  @Test("the earlier of two overlapping stretches holds the shared ground")
  func overlap() {
    let overlapping = [
      ProfileClass(from: 0, to: 600, color: "#f00", label: "Path"),
      ProfileClass(from: 400, to: 1_000, color: "#00f", label: "Trail"),
    ]
    #expect(stretchAt(overlapping, distance: 500)?.label == "Path")
    #expect(stretchAt(overlapping, distance: 600)?.label == "Trail")
    #expect(stretchAt(overlapping, distance: 600)?.from == 600)
    #expect(stretchAt([ProfileRange](), distance: 0) == nil)
  }
}
