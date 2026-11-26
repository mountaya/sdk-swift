import Testing

@testable import MountayaGeo

@Suite("PlotCommand")
struct PlotCommandTests {
  @Test("a command is told by its kind and its point")
  func equality() {
    let point = PlotPoint(x: 0, y: 100)
    #expect(PlotCommand.move(point) == .move(PlotPoint(x: 0, y: 100)))
    #expect(PlotCommand.move(point) != .line(point))
    #expect(PlotCommand.close == .close)
  }
}
