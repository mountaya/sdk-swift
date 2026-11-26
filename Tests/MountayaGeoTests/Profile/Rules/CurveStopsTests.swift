import Testing

@testable import MountayaGeo

@Suite("curveStops")
struct CurveStopsTests {
  @Test("one stretch is painted between two hard edges, uncovered ground stated as no colour")
  func one() {
    #expect(
      curveStops([CurveColor(from: 200, to: 400, color: "#f00")], totalDistance: 1_000)
        == [
          CurveStop(offset: 0, color: nil), CurveStop(offset: 0.2, color: nil),
          CurveStop(offset: 0.2, color: "#f00"), CurveStop(offset: 0.4, color: "#f00"),
          CurveStop(offset: 0.4, color: nil), CurveStop(offset: 1, color: nil),
        ])
  }

  @Test("touching stretches of one colour state their boundary once")
  func oneColour() {
    #expect(
      curveStops(
        [
          CurveColor(from: 0, to: 500, color: "#f00"),
          CurveColor(from: 500, to: 1_000, color: "#f00"),
        ], totalDistance: 1_000)
        == [
          CurveStop(offset: 0, color: "#f00"), CurveStop(offset: 0.5, color: "#f00"),
          CurveStop(offset: 1, color: "#f00"),
        ])
  }

  @Test("a window places the stretches it holds and cuts one crossing its end")
  func window() {
    let window = ProfileRange(from: 200, to: 700)
    #expect(
      curveStops(
        [CurveColor(from: 0, to: 450, color: "#f00")], totalDistance: 1_000, window: window)
        == [
          CurveStop(offset: 0, color: "#f00"), CurveStop(offset: 0.5, color: "#f00"),
          CurveStop(offset: 0.5, color: nil), CurveStop(offset: 1, color: nil),
        ])
    #expect(
      curveStops(
        [CurveColor(from: 800, to: 900, color: "#f00")], totalDistance: 1_000, window: window
      ).isEmpty)
  }

  @Test("no stretch of any length is no gradient")
  func none() {
    #expect(curveStops([], totalDistance: 1_000).isEmpty)
    #expect(
      curveStops([CurveColor(from: 300, to: 300, color: "#f00")], totalDistance: 1_000).isEmpty)
    #expect(curveStops([CurveColor(from: 0, to: 300, color: "#f00")], totalDistance: 0).isEmpty)
  }
}
