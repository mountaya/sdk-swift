/// ShapePaint is how one shape of a glyph is drawn, as `glyphPaint(_:in:)` answers it: whether its
/// inside is filled and its outline stroked, each in the current colour, the colour the surface
/// draws its glyph in, and how a stroke is drawn.
///
/// Two are equal where every member is, the numbers compared as every value of the geo layer
/// compares them, and equal values hash alike.
public struct ShapePaint: Sendable, Hashable {
  /// LineCap is how each end of a stroked line is drawn, by the keyword SVG spells it with.
  public enum LineCap: String, Sendable, Hashable, CaseIterable {
    /// butt ends a line where it ends.
    case butt
    /// round ends a line in a half disc as wide as the stroke, so a line of no length is a dot.
    case round
    /// square ends a line half the stroke's width past where it ends.
    case square
  }

  /// LineJoin is how a stroked line turns a corner, by the keyword SVG spells it with.
  public enum LineJoin: String, Sendable, Hashable, CaseIterable {
    /// arcs turns a corner in arcs; a renderer that draws none draws a miter.
    case arcs
    /// bevel cuts a corner off.
    case bevel
    /// miter turns a corner sharp, up to the miter limit.
    case miter
    /// miterClip turns a corner sharp and clips it at the miter limit; a renderer that draws no
    /// clipped miter draws a miter.
    case miterClip = "miter-clip"
    /// round turns a corner in an arc.
    case round
  }

  /// FillRule is how a fill reads which parts of a shape are inside it, by the keyword SVG spells
  /// it with.
  public enum FillRule: String, Sendable, Hashable, CaseIterable {
    /// nonZero reads a point as inside where the outline winds around it.
    case nonZero = "nonzero"
    /// evenOdd reads a point as inside where a line from it crosses the outline an odd number of
    /// times.
    case evenOdd = "evenodd"
  }

  /// isFilled tells whether the shape's inside is filled in the current colour.
  public var isFilled: Bool
  /// isStroked tells whether the shape's outline is stroked in the current colour.
  public var isStroked: Bool
  /// strokeWidth is the stroke's width, in units of the set's box.
  public var strokeWidth: Double
  /// lineCap is how each end of a stroked line is drawn.
  public var lineCap: LineCap
  /// lineJoin is how a stroked line turns a corner.
  public var lineJoin: LineJoin
  /// miterLimit is how far a miter may reach, in stroke widths, before the corner is drawn
  /// bevelled instead.
  public var miterLimit: Double
  /// fillRule is how a fill reads which parts of the shape are inside it.
  public var fillRule: FillRule

  /// Creates the paint of a shape.
  public init(
    isFilled: Bool, isStroked: Bool, strokeWidth: Double, lineCap: LineCap, lineJoin: LineJoin,
    miterLimit: Double, fillRule: FillRule
  ) {
    self.isFilled = isFilled
    self.isStroked = isStroked
    self.strokeWidth = strokeWidth
    self.lineCap = lineCap
    self.lineJoin = lineJoin
    self.miterLimit = miterLimit
    self.fillRule = fillRule
  }

  /// Two paints are equal where every member is, the numbers being the same numbers.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.isFilled == rhs.isFilled && lhs.isStroked == rhs.isStroked
      && sameNumber(lhs.strokeWidth, rhs.strokeWidth) && lhs.lineCap == rhs.lineCap
      && lhs.lineJoin == rhs.lineJoin && sameNumber(lhs.miterLimit, rhs.miterLimit)
      && lhs.fillRule == rhs.fillRule
  }

  /// hash feeds every member, the numbers as the same-number relation reads them.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(isFilled)
    hasher.combine(isStroked)
    hasher.combine(sameNumber: strokeWidth)
    hasher.combine(lineCap)
    hasher.combine(lineJoin)
    hasher.combine(sameNumber: miterLimit)
    hasher.combine(fillRule)
  }
}
