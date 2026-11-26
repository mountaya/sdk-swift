import Testing

@testable import MountayaGeo

@Suite("CurvePin")
struct CurvePinTests {
  private let place = ProfilePlace(.atDistance(id: "col", distance: 250), name: "Col")

  @Test("two pins are equal where every member is the same")
  func equality() {
    let pin = CurvePin(key: "col#0", place: place, distance: 250, x: 50, y: 51, altitude: 1_250)
    #expect(
      pin == CurvePin(key: "col#0", place: place, distance: 250, x: 50, y: 51, altitude: 1_250))
    #expect(
      pin.hashValue
        == CurvePin(key: "col#0", place: place, distance: 250, x: 50, y: 51, altitude: 1_250)
        .hashValue)
    #expect(
      pin != CurvePin(key: "col#1", place: place, distance: 250, x: 50, y: 51, altitude: 1_250))
  }
}
