import Testing

@testable import MountayaElements

@Suite("MarkerCallout")
@MainActor
struct MarkerCalloutTests {
  @Test("a label shown counts the camera's moves, and none is counted while no label shows")
  func moves() {
    let callout = MarkerCallout()
    callout.cameraMoved()
    #expect(callout.markerId == nil)
    #expect(callout.moves == 0)

    callout.show("hut")
    callout.cameraMoved()
    callout.cameraMoved()
    #expect(callout.markerId == "hut")
    #expect(callout.moves == 2)

    callout.show(nil)
    callout.cameraMoved()
    #expect(callout.markerId == nil)
    #expect(callout.moves == 2)
  }
}
