import Testing

@testable import MountayaGeo

@Suite("ShapePaint")
struct ShapePaintTests {
  private static func paint(width: Double, miter: Double = 4) -> ShapePaint {
    ShapePaint(
      isFilled: false, isStroked: true, strokeWidth: width, lineCap: .round, lineJoin: .round,
      miterLimit: miter, fillRule: .nonZero)
  }

  @Test("each keyword is the one SVG spells")
  func keywords() {
    #expect(ShapePaint.LineCap.allCases.map(\.rawValue) == ["butt", "round", "square"])
    #expect(
      ShapePaint.LineJoin.allCases.map(\.rawValue)
        == ["arcs", "bevel", "miter", "miter-clip", "round"])
    #expect(ShapePaint.FillRule.allCases.map(\.rawValue) == ["nonzero", "evenodd"])
  }

  @Test("two paints are equal where they hold the same numbers, NaN as NaN and 0 apart from -0")
  func equality() {
    #expect(Self.paint(width: 2) == Self.paint(width: 2))
    #expect(Self.paint(width: .nan) == Self.paint(width: .nan))
    #expect(Self.paint(width: .nan).hashValue == Self.paint(width: .nan).hashValue)
    #expect(Self.paint(width: 0) != Self.paint(width: -0.0))
    #expect(Self.paint(width: 2, miter: 4) != Self.paint(width: 2, miter: 10))
    var filled = Self.paint(width: 2)
    filled.isFilled = true
    #expect(filled != Self.paint(width: 2))
  }
}
