import Testing

@testable import MountayaGeo

@Suite("AxisLabelBox")
struct AxisLabelBoxTests {
  @Test("two boxes are equal where the keys are written alike and the edges are the same numbers")
  func equality() {
    #expect(
      AxisLabelBox(key: "a", left: 0, right: 60) == AxisLabelBox(key: "a", left: 0, right: 60))
    #expect(
      AxisLabelBox(key: "a", left: 0, right: 60).hashValue
        == AxisLabelBox(key: "a", left: 0, right: 60).hashValue)
    #expect(
      AxisLabelBox(key: "a", left: 0, right: 60) != AxisLabelBox(key: "b", left: 0, right: 60))
    #expect(
      AxisLabelBox(key: "a", left: 0, right: 60) != AxisLabelBox(key: "a", left: -0.0, right: 60))
  }
}
