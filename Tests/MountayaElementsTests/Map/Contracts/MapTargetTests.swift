import MountayaClient
import Testing

@testable import MountayaElements

@Suite("MapTarget")
struct MapTargetTests {
  @Test("a target holds no marker and no stretch until it is given them, and compares by both")
  func members() {
    let none = MapTarget()
    #expect(none.lngLat == nil && none.stretch == nil)
    let marked = MapTarget(lngLat: [6, 45])
    #expect(marked != none)
    #expect(marked == MapTarget(lngLat: [6, 45], stretch: nil))
  }
}
