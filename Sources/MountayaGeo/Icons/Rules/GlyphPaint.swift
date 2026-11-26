/// glyphLineEnds is the cap and the join a set draws its lines with, under either paint: round, so
/// a dot drawn as a stroke a hundredth of a unit long is a dot, where butt caps draw nothing.
let glyphLineEnds = (cap: ShapePaint.LineCap.round, join: ShapePaint.LineJoin.round)

/// glyphMiterLimit is the miter limit a shape that states none is drawn with: SVG's own, 4. A
/// platform's drawing API may default to another, CoreGraphics' to 10, so a renderer states it
/// rather than inheriting its platform's.
let glyphMiterLimit: Double = 4

/// glyphFillRule is the fill rule a shape that states none is drawn with: SVG's own, non-zero.
let glyphFillRule = ShapePaint.FillRule.nonZero

/// glyphPaint answers how `shape`, one shape of a glyph of `set`, is drawn.
///
/// A fill set fills each shape in the current colour and strokes none; a stroke set strokes each
/// shape in the current colour and fills none. Either draws a stroke at the set's width, with round
/// caps and joins, at SVG's miter limit of 4, and fills by the non-zero rule. What the shape states
/// of its own replaces the set's for that shape alone: its `fill` and its `stroke`, `currentColor`
/// or `none`, its `stroke-linecap`, its `stroke-linejoin`, its `stroke-miterlimit` and its
/// `fill-rule`, each read without regard to letter case. A value `parseGlyph(_:)` would drop is no
/// statement, whoever built the shape, and a shape never states a width: the width is the set's.
/// So a fill set strokes a shape that asks for a stroke of its own at the set's width with round
/// ends, and a stroke set strokes a dot that fills itself around its edge as well, unless the dot
/// states a stroke of `none` (`geo.icons.glyph-paint`).
///
/// A shape that states nothing answers the set's own paint, which a renderer may state once on
/// whatever holds every shape of the glyph.
public func glyphPaint(_ shape: GlyphShape, in set: GlyphSet) -> ShapePaint {
  let fills = set.paint == .fill
  func stated(_ name: String) -> String? {
    shape.attributes[name].flatMap { keptGlyphValue(name, value: $0) }.map(asciiLowercase)
  }
  let fillRule = shape.attributes["fill-rule"].map { asciiLowercase(trimWhiteSpace($0)) }
  return ShapePaint(
    isFilled: stated("fill").map { $0 != "none" } ?? fills,
    isStroked: stated("stroke").map { $0 != "none" } ?? !fills,
    strokeWidth: set.strokeWidth,
    lineCap: stated("stroke-linecap").flatMap(ShapePaint.LineCap.init(rawValue:))
      ?? glyphLineEnds.cap,
    lineJoin: stated("stroke-linejoin").flatMap(ShapePaint.LineJoin.init(rawValue:))
      ?? glyphLineEnds.join,
    miterLimit: stated("stroke-miterlimit").flatMap { Double($0) } ?? glyphMiterLimit,
    fillRule: fillRule == ShapePaint.FillRule.evenOdd.rawValue ? .evenOdd : glyphFillRule)
}
