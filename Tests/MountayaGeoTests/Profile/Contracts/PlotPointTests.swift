import Testing

@testable import MountayaGeo

@Suite("PlotPoint")
struct PlotPointTests {
  @Test("two points are equal where both numbers are the same")
  func equality() {
    #expect(PlotPoint(x: 50, y: 51) == PlotPoint(x: 50, y: 51))
    #expect(PlotPoint(x: 50, y: 51).hashValue == PlotPoint(x: 50, y: 51).hashValue)
    #expect(PlotPoint(x: 0, y: 51) != PlotPoint(x: -0.0, y: 51))
    #expect(PlotPoint(x: .nan, y: 51) == PlotPoint(x: .nan, y: 51))
  }
}
