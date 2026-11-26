import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("AmenityStack")
struct AmenityStackTests {
  @Test("two stacks are equal where the pin and the services are")
  func equality() {
    let pin = CurvePin(
      key: "col#0", place: ProfilePlace(.atDistance(id: "col", distance: 0)), distance: 0, x: 0,
      y: 0, altitude: 0)
    let stack = AmenityStack(pin: pin, shown: ["water"], counted: 1, named: ["water", "food"])
    #expect(
      stack == AmenityStack(pin: pin, shown: ["water"], counted: 1, named: ["water", "food"]))
    #expect(
      stack != AmenityStack(pin: pin, shown: ["water"], counted: 2, named: ["water", "food"]))
    #expect(
      stack.hashValue
        == AmenityStack(pin: pin, shown: ["water"], counted: 1, named: ["water", "food"]).hashValue)
  }
}
