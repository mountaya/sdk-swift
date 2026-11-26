import CoreGraphics
import Testing

@testable import MountayaElements

@Suite("svgTransform")
struct SvgTransformTests {
  private static func applied(_ list: String, x: CGFloat, y: CGFloat) -> CGPoint {
    CGPoint(x: x, y: y).applying(svgTransform(list))
  }

  private static func near(_ a: CGPoint, _ b: CGPoint) -> Bool {
    abs(a.x - b.x) < 1e-9 && abs(a.y - b.y) < 1e-9
  }

  @Test("each transform SVG names, its arguments separated by white space or a comma")
  func each() {
    #expect(Self.applied("translate(2 3)", x: 1, y: 1) == CGPoint(x: 3, y: 4))
    #expect(Self.applied("translate(2)", x: 1, y: 1) == CGPoint(x: 3, y: 1))
    #expect(Self.applied("scale(2,3)", x: 1, y: 1) == CGPoint(x: 2, y: 3))
    #expect(Self.applied("scale(2)", x: 1, y: 1) == CGPoint(x: 2, y: 2))
    #expect(Self.applied("matrix(1 2 3 4 5 6)", x: 1, y: 1) == CGPoint(x: 9, y: 12))
    #expect(Self.near(Self.applied("rotate(90)", x: 1, y: 0), CGPoint(x: 0, y: 1)))
    #expect(Self.near(Self.applied("rotate(90 12 12)", x: 24, y: 12), CGPoint(x: 12, y: 24)))
    #expect(Self.near(Self.applied("skewX(45)", x: 0, y: 1), CGPoint(x: 1, y: 1)))
    #expect(Self.near(Self.applied("skewY(45)", x: 1, y: 0), CGPoint(x: 1, y: 1)))
  }

  @Test("a list applies its last transform first, as SVG nests a group's around a shape's own")
  func order() {
    #expect(Self.applied("translate(2 2) scale(3)", x: 1, y: 1) == CGPoint(x: 5, y: 5))
    #expect(Self.applied("scale(3) translate(2 2)", x: 1, y: 1) == CGPoint(x: 9, y: 9))
    #expect(Self.applied(" translate(1),translate(1) ", x: 0, y: 0) == CGPoint(x: 2, y: 0))
    #expect(Self.applied("translate ( 1 , 2 )", x: 0, y: 0) == CGPoint(x: 1, y: 2))
  }

  @Test("a list holding anything else is no transform at all, and so is an empty one")
  func refused() {
    for list in [
      "translate(2) foo(3)", "Translate(2)", "rotate(1 2)", "matrix(1 2 3)", "scale()",
      "translate(1 2 3)", "translate(1", "translate(1)x",
    ] {
      #expect(svgTransform(list) == .identity, "\(list)")
    }
    #expect(svgTransform("") == .identity)
    #expect(svgTransform("   ") == .identity)
  }
}
