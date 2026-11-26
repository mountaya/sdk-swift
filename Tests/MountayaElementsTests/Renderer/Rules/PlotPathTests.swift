import MountayaGeo
import SwiftUI
import Testing

@testable import MountayaElements

@Suite("plotPath")
struct PlotPathTests {
  @Test("a point of the profile's square stands where the box stretches it")
  func point() {
    let size = CGSize(width: 300, height: 120)

    #expect(plotPoint(PlotPoint(x: 50, y: 25), in: size) == CGPoint(x: 150, y: 30))
    #expect(plotPoint(PlotPoint(x: 0, y: 0), in: size) == .zero)
    #expect(plotPoint(PlotPoint(x: 100, y: 100), in: size) == CGPoint(x: 300, y: 120))
  }

  @Test("commands draw the shape they state, closed where they close it")
  func commands() {
    let area = plotPath(
      [
        .move(PlotPoint(x: 0, y: 96)), .line(PlotPoint(x: 0, y: 6)),
        .line(PlotPoint(x: 100, y: 50)), .line(PlotPoint(x: 100, y: 96)), .close,
      ], in: CGSize(width: 200, height: 100))

    #expect(area.boundingRect == CGRect(x: 0, y: 6, width: 200, height: 90))
    #expect(area.contains(CGPoint(x: 20, y: 80)))
    #expect(!area.contains(CGPoint(x: 180, y: 20)), "above the line from (0, 6) to (200, 50)")
  }

  @Test("points draw a line through them, and no point no line")
  func points() {
    let size = CGSize(width: 200, height: 100)
    let line = plotPath([PlotPoint(x: 0, y: 50), PlotPoint(x: 50, y: 0)], in: size)

    #expect(line.boundingRect == CGRect(x: 0, y: 0, width: 100, height: 50))
    #expect(plotPath([PlotPoint](), in: size).isEmpty)
  }
}
