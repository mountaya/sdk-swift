import MountayaGeo
import SwiftUI
import Testing

@testable import MountayaElements

@Suite("GlyphFigure")
struct GlyphFigureTests {
  @Test("a figure keeps its outline apart from its transform, so a stroke scales as SVG scales it")
  func apart() throws {
    let set = try #require(
      GlyphSet(
        name: "test", paint: .stroke,
        markup: ["dash": #"<path d="M0 0h1" transform="scale(4)"/>"#]))
    let figure = try #require(glyphFigures("dash", in: set)?.first)

    #expect(figure.path.boundingRect == CGRect(x: 0, y: 0, width: 1, height: 0))
    #expect(figure.transform == CGAffineTransform(scaleX: 4, y: 4))
    #expect(figure.paint.strokeWidth == 2)
  }
}
