import CoreGraphics
import MountayaGeo
import Testing

@testable import MountayaElements

@Suite("glyphFigures")
struct GlyphFiguresTests {
  @Test("a glyph is a figure for each shape that draws, painted as its set paints it")
  func figures() throws {
    let figures = try #require(glyphFigures("map-pin", in: .marker))
    let shapes = parseGlyph(try #require(GlyphSet.marker.markup["map-pin"]))

    #expect(figures.count == shapes.count)
    #expect(figures.map(\.paint) == shapes.map { glyphPaint($0, in: .marker) })
    #expect(figures.allSatisfy { $0.paint.isStroked && !$0.paint.isFilled })
  }

  @Test("a glyph the set does not hold is no figures; a shape that draws nothing is no figure")
  func missing() throws {
    let set = try #require(
      GlyphSet(
        name: "test", paint: .fill,
        markup: ["dot": #"<circle r="0"/><circle cx="4" cy="4" r="2" transform="scale(2)"/>"#]))

    #expect(glyphFigures("hut", in: .control) == nil)
    let figures = try #require(glyphFigures("dot", in: set))
    #expect(figures.count == 1)
    #expect(figures.first?.transform == CGAffineTransform(scaleX: 2, y: 2))
    #expect(figures.first?.paint.isFilled == true)
  }

  @Test("markup the glyph allowlist does not keep draws nothing")
  func allowlist() throws {
    let set = try #require(
      GlyphSet(
        name: "test", paint: .stroke,
        markup: ["hostile": #"<script>x</script><image href="https://example.invalid/a.png"/>"#]))

    #expect(glyphFigures("hostile", in: set)?.isEmpty == true)
  }

  @Test("CoreGraphics draws SVG's caps, and a miter for the joins it has none of")
  func lineEnds() {
    #expect(ShapePaint.LineCap.allCases.map(cgLineCap) == [.butt, .round, .square])
    #expect(
      ShapePaint.LineJoin.allCases.map(cgLineJoin) == [.miter, .bevel, .miter, .miter, .round])
  }
}
