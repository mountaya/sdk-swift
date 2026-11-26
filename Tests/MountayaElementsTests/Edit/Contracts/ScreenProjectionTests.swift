import Testing

@testable import MountayaElements

@Suite("ScreenProjection")
@MainActor
struct ScreenProjectionTests {
  @Test("a projection is the pair of functions it is made of, to the screen and back")
  func pair() {
    let projection = ScreenProjection(
      point: { [$0[0] * 2, $0[1] * 2] }, position: { [$0[0] / 2, $0[1] / 2] })

    #expect(projection.point([6, 45]) == [12, 90])
    #expect(projection.position([12, 90]) == [6, 45])
  }
}
