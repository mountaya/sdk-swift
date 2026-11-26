import Testing

@testable import MountayaGeo

@Suite("glyphPaint")
struct GlyphPaintTests {
  private static func set(_ paint: GlyphSet.Paint, width: Double = 2) throws -> GlyphSet {
    try #require(GlyphSet(name: "case", paint: paint, strokeWidth: width, markup: [:]))
  }

  private static func shape(_ attributes: [String: String], tag: String = "path") -> GlyphShape {
    GlyphShape(tag: tag, attributes: attributes)
  }

  private static func paint(
    filled: Bool, stroked: Bool, width: Double = 2, cap: ShapePaint.LineCap = .round,
    join: ShapePaint.LineJoin = .round, miter: Double = 4, rule: ShapePaint.FillRule = .nonZero
  ) -> ShapePaint {
    ShapePaint(
      isFilled: filled, isStroked: stroked, strokeWidth: width, lineCap: cap, lineJoin: join,
      miterLimit: miter, fillRule: rule)
  }

  @Test("a stroke set strokes each shape in the current colour at its width, and fills none")
  func strokeSet() throws {
    #expect(
      glyphPaint(Self.shape(["d": "M5 12h14"]), in: try Self.set(.stroke))
        == Self.paint(filled: false, stroked: true))
    #expect(
      glyphPaint(Self.shape(["d": "M3 3h12"]), in: try Self.set(.stroke, width: 3))
        == Self.paint(filled: false, stroked: true, width: 3))
  }

  @Test("a fill set fills each shape in the current colour, and strokes none")
  func fillSet() throws {
    #expect(
      glyphPaint(Self.shape(["d": "M2 2h20v20H2z"]), in: try Self.set(.fill))
        == Self.paint(filled: true, stroked: false))
  }

  @Test("a shape that states nothing is drawn in the set's caps, joins, miter limit and fill rule")
  func setsOwn() throws {
    for paint in GlyphSet.Paint.allCases {
      let drawn = glyphPaint(GlyphShape(tag: "circle", attributes: [:]), in: try Self.set(paint))
      #expect(drawn.lineCap == .round)
      #expect(drawn.lineJoin == .round)
      #expect(drawn.miterLimit == 4)
      #expect(drawn.fillRule == .nonZero)
    }
  }

  @Test("a dot a stroke set fills of its own is stroked around too, unless it states no stroke")
  func dots() throws {
    let stroke = try Self.set(.stroke)

    #expect(
      glyphPaint(Self.shape(["r": ".5", "fill": "currentColor"], tag: "circle"), in: stroke)
        == Self.paint(filled: true, stroked: true))
    #expect(
      glyphPaint(
        Self.shape(["r": ".5", "fill": "currentColor", "stroke": "none"], tag: "circle"),
        in: stroke) == Self.paint(filled: true, stroked: false))
  }

  @Test("a fill set strokes a shape that asks for a stroke at the set's width, with round ends")
  func fillSetStroke() throws {
    #expect(
      glyphPaint(
        Self.shape(["d": "M12 17h.01", "fill": "none", "stroke": "currentColor"]),
        in: try Self.set(.fill, width: 1.5))
        == Self.paint(filled: false, stroked: true, width: 1.5))
  }

  @Test("a shape's own cap, join, miter limit and fill rule replace the set's for it alone")
  func ownLineEnds() throws {
    let stroke = try Self.set(.stroke, width: 3)

    #expect(
      glyphPaint(
        Self.shape([
          "d": "M3 3h12", "stroke-linecap": "square", "stroke-linejoin": "miter",
          "stroke-miterlimit": "10",
        ]), in: stroke)
        == Self.paint(filled: false, stroked: true, width: 3, cap: .square, join: .miter, miter: 10)
    )
    #expect(
      glyphPaint(
        Self.shape(["d": "M0 0h24v24H0zM6 6v12h12V6z", "fill-rule": "evenodd"]),
        in: try Self.set(.fill))
        == Self.paint(filled: true, stroked: false, rule: .evenOdd))
    #expect(
      glyphPaint(Self.shape(["d": "M0 0", "stroke-linejoin": "miter-clip"]), in: stroke).lineJoin
        == .miterClip)
    #expect(
      glyphPaint(Self.shape(["d": "M0 0", "stroke-miterlimit": "4."]), in: stroke).miterLimit == 4)
  }

  @Test("what a shape states is read without regard to case")
  func anyCase() throws {
    #expect(
      glyphPaint(
        Self.shape([
          "d": "M0 0h1", "fill": "CURRENTCOLOR", "stroke": "None", "stroke-linecap": "BUTT",
          "stroke-linejoin": "Bevel", "fill-rule": "EVENODD",
        ]), in: try Self.set(.stroke))
        == Self.paint(filled: true, stroked: false, cap: .butt, join: .bevel, rule: .evenOdd))
    #expect(
      glyphPaint(Self.shape(["d": "M0 0", "fill-rule": " EvenOdd\t"]), in: try Self.set(.fill))
        .fillRule == .evenOdd)
  }

  @Test("a value the parse would drop is no statement, whoever built the shape")
  func dropped() throws {
    let stroke = try Self.set(.stroke)

    #expect(
      glyphPaint(
        Self.shape([
          "d": "M0 0", "fill": "#ffffff", "stroke": "red", "stroke-linecap": "flat",
          "stroke-linejoin": "sharp", "stroke-miterlimit": "0.5", "fill-rule": "odd",
        ]), in: stroke) == Self.paint(filled: false, stroked: true))
    #expect(
      glyphPaint(Self.shape(["d": "M0 0", "stroke-miterlimit": "1e1"]), in: stroke).miterLimit == 4)
    // A shape never states a width: the width is the set's.
    #expect(
      glyphPaint(Self.shape(["d": "M0 0", "stroke-width": "9"]), in: stroke).strokeWidth == 2)
  }

  @Test("each shape of a glyph is painted alone")
  func eachShape() throws {
    let stroke = try Self.set(.stroke)
    let shapes = parseGlyph(
      #"<path d="M12 2v20"/><circle cx="12" cy="12" r="1" fill="currentColor" stroke="none"/>"#
        + #"<path d="M2 12h20" stroke-linecap="square"/>"#)

    #expect(
      shapes.map { glyphPaint($0, in: stroke) } == [
        Self.paint(filled: false, stroked: true),
        Self.paint(filled: true, stroked: false),
        Self.paint(filled: false, stroked: true, cap: .square),
      ])
  }
}
