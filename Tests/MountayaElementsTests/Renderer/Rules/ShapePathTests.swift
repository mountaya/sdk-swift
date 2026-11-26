import MountayaGeo
import SwiftUI
import Testing

@testable import MountayaElements

@Suite("shapePath")
struct ShapePathTests {
  private static func elements(_ path: Path?) -> [Path.Element] {
    var elements: [Path.Element] = []
    path?.forEach { elements.append($0) }
    return elements
  }

  private static func data(_ d: String) -> [Path.Element] {
    elements(svgPathData(d))
  }

  private static func shape(_ tag: String, attributes: [String: String]) -> [Path.Element] {
    elements(shapePath(GlyphShape(tag: tag, attributes: attributes)))
  }

  @Test("a move, lines and a close, absolute and relative, each repeated over further pairs")
  func lines() {
    #expect(
      Self.data("M5 12h14") == [.move(to: CGPoint(x: 5, y: 12)), .line(to: CGPoint(x: 19, y: 12))])
    #expect(
      Self.data("m1 1 2 2 3 3")
        == [
          .move(to: CGPoint(x: 1, y: 1)), .line(to: CGPoint(x: 3, y: 3)),
          .line(to: CGPoint(x: 6, y: 6)),
        ])
    #expect(
      Self.data("M1 1 L2 2 3 3V5H0v-1h2z")
        == [
          .move(to: CGPoint(x: 1, y: 1)), .line(to: CGPoint(x: 2, y: 2)),
          .line(to: CGPoint(x: 3, y: 3)),
          .line(to: CGPoint(x: 3, y: 5)), .line(to: CGPoint(x: 0, y: 5)),
          .line(to: CGPoint(x: 0, y: 4)),
          .line(to: CGPoint(x: 2, y: 4)), .closeSubpath,
        ])
  }

  @Test("numbers are written with nothing between them where a sign or a point ends one")
  func numbers() {
    #expect(
      Self.data("M1-2.5.5.5e1")
        == [.move(to: CGPoint(x: 1, y: -2.5)), .line(to: CGPoint(x: 0.5, y: 5))])
    #expect(
      Self.data("M1,2,3,4") == [.move(to: CGPoint(x: 1, y: 2)), .line(to: CGPoint(x: 3, y: 4))])
    // SwiftUI holds a path's points at single precision, so each number here is one it holds
    // exactly.
    #expect(
      Self.data("M 1e1 -5E-1 L+2. .5")
        == [.move(to: CGPoint(x: 10, y: -0.5)), .line(to: CGPoint(x: 2, y: 0.5))])
    // An `e` with no digits after it is no exponent, and then no command.
    #expect(Self.data("M1 2e") == [.move(to: CGPoint(x: 1, y: 2))])
  }

  @Test("a path draws up to the command holding its first error, and nothing before a move")
  func errors() {
    #expect(Self.data("M0 0 L 1") == [.move(to: CGPoint(x: 0, y: 0))])
    #expect(Self.data("L0 0 L 1 1").isEmpty)
    #expect(Self.data("").isEmpty)
    #expect(
      Self.data("M0 0 h10 x 5") == [
        .move(to: CGPoint(x: 0, y: 0)), .line(to: CGPoint(x: 10, y: 0)),
      ])
    #expect(Self.data("M0 0 Z 5 5") == [.move(to: CGPoint(x: 0, y: 0)), .closeSubpath])
    #expect(Self.data("M0 0 L1,,1") == [.move(to: CGPoint(x: 0, y: 0))])
    #expect(Self.data("M0 0 L1e999 1") == [.move(to: CGPoint(x: 0, y: 0))])
  }

  @Test("a path drawn after a close starts where the closed one started")
  func afterClose() {
    #expect(
      Self.data("M0 0L10 0 10 10z l5 5")
        == [
          .move(to: CGPoint(x: 0, y: 0)), .line(to: CGPoint(x: 10, y: 0)),
          .line(to: CGPoint(x: 10, y: 10)), .closeSubpath, .move(to: CGPoint(x: 0, y: 0)),
          .line(to: CGPoint(x: 5, y: 5)),
        ])
    #expect(
      Self.data("M2 2h1zm1 1h1")
        == [
          .move(to: CGPoint(x: 2, y: 2)), .line(to: CGPoint(x: 3, y: 2)), .closeSubpath,
          .move(to: CGPoint(x: 3, y: 3)), .line(to: CGPoint(x: 4, y: 3)),
        ])
  }

  @Test("a smooth curve reflects the control point of the curve before it, where it is one")
  func smooth() {
    #expect(
      Self.data("M0 0C1 2 3 4 5 6S9 9 10 10")
        == [
          .move(to: CGPoint(x: 0, y: 0)),
          .curve(
            to: CGPoint(x: 5, y: 6), control1: CGPoint(x: 1, y: 2), control2: CGPoint(x: 3, y: 4)),
          .curve(
            to: CGPoint(x: 10, y: 10), control1: CGPoint(x: 7, y: 8), control2: CGPoint(x: 9, y: 9)),
        ])
    #expect(
      Self.data("M0 0Q5 5 10 0T20 0")
        == [
          .move(to: CGPoint(x: 0, y: 0)),
          .quadCurve(to: CGPoint(x: 10, y: 0), control: CGPoint(x: 5, y: 5)),
          .quadCurve(to: CGPoint(x: 20, y: 0), control: CGPoint(x: 15, y: -5)),
        ])
    // After a line, a smooth curve's control point is the current point.
    #expect(
      Self.data("M0 0L4 0s1 1 2 0")
        == [
          .move(to: CGPoint(x: 0, y: 0)), .line(to: CGPoint(x: 4, y: 0)),
          .curve(
            to: CGPoint(x: 6, y: 0), control1: CGPoint(x: 4, y: 0), control2: CGPoint(x: 5, y: 1)),
        ])
    #expect(
      Self.data("M0 0Q1 1 2 0L4 0t2 0")
        == [
          .move(to: CGPoint(x: 0, y: 0)),
          .quadCurve(to: CGPoint(x: 2, y: 0), control: CGPoint(x: 1, y: 1)),
          .line(to: CGPoint(x: 4, y: 0)),
          .quadCurve(to: CGPoint(x: 6, y: 0), control: CGPoint(x: 4, y: 0)),
        ])
  }

  @Test("an arc is drawn as cubic curves ending where it ends, on the side its flags choose")
  func arcs() {
    let upper = svgPathData("M0 0a5 5 0 0 1 10 0").boundingRect
    let lower = svgPathData("M0 0a5 5 0 1010 0").boundingRect
    #expect(abs(upper.minY + 5) < 0.01 && abs(upper.maxY) < 0.01)
    #expect(abs(lower.maxY - 5) < 0.01 && abs(lower.minY) < 0.01)
    #expect(svgPathData("M0 0a5 5 0 0 1 10 0").currentPoint == CGPoint(x: 10, y: 0))
    // A whole turn but for its end is drawn in four quarters at most.
    let large = Self.data("M0 0A5 5 0 1 1 0.0001 0")
    #expect(large.count <= 5)
    // Radii too small to reach the end are scaled up until they do; a sign is dropped.
    #expect(
      abs(svgPathData("M0 0A1 1 0 0 1 10 0").boundingRect.height - 5) < 0.01)
    #expect(
      abs(svgPathData("M0 0A-5 -5 0 0 1 10 0").boundingRect.minY + 5) < 0.01)
    // A radius of 0 is a line, and an arc ending where it starts is nothing.
    #expect(
      Self.data("M0 0A0 5 0 0 1 10 0") == [
        .move(to: CGPoint(x: 0, y: 0)), .line(to: CGPoint(x: 10, y: 0)),
      ])
    #expect(Self.data("M3 3A5 5 0 0 1 3 3") == [.move(to: CGPoint(x: 3, y: 3))])
    // The axes turn with the rotation the arc states.
    let turned = svgPathData("M0 0A10 5 90 0 1 0 20").boundingRect
    #expect(abs(turned.width - 5) < 0.01 && abs(turned.height - 20) < 0.01)
  }

  @Test("each shape is the outline SVG lays it out as, and one of no size draws nothing")
  func shapes() {
    #expect(
      shapePath(GlyphShape(tag: "circle", attributes: ["cx": "12", "cy": "10", "r": "3"]))?
        .boundingRect == CGRect(x: 9, y: 7, width: 6, height: 6))
    #expect(Self.shape("circle", attributes: ["r": "0"]).isEmpty)
    #expect(Self.shape("circle", attributes: ["cx": "1"]).isEmpty)
    #expect(
      shapePath(GlyphShape(tag: "ellipse", attributes: ["cx": "5", "rx": "4", "ry": "2"]))?
        .boundingRect == CGRect(x: 1, y: -2, width: 8, height: 4))
    #expect(
      shapePath(GlyphShape(tag: "ellipse", attributes: ["rx": "4"]))?.boundingRect
        == CGRect(x: -4, y: -4, width: 8, height: 8))
    #expect(
      shapePath(
        GlyphShape(tag: "rect", attributes: ["x": "2", "y": "3", "width": "4", "height": "5"]))?
        .boundingRect == CGRect(x: 2, y: 3, width: 4, height: 5))
    #expect(Self.shape("rect", attributes: ["width": "4"]).isEmpty)
    #expect(Self.shape("rect", attributes: ["width": "4", "height": "-1"]).isEmpty)
    #expect(
      Self.shape("line", attributes: ["x1": "1", "y1": "2", "x2": "3", "y2": "4"])
        == [.move(to: CGPoint(x: 1, y: 2)), .line(to: CGPoint(x: 3, y: 4))])
    #expect(
      Self.shape("polygon", attributes: ["points": "0,0 4,0 4 4"])
        == [
          .move(to: CGPoint(x: 0, y: 0)), .line(to: CGPoint(x: 4, y: 0)),
          .line(to: CGPoint(x: 4, y: 4)),
          .closeSubpath,
        ])
    #expect(
      Self.shape("polyline", attributes: ["points": "0 0, 4 0 9"])
        == [.move(to: CGPoint(x: 0, y: 0)), .line(to: CGPoint(x: 4, y: 0))])
    #expect(Self.shape("polyline", attributes: ["points": ""]).isEmpty)
    #expect(Self.shape("path", attributes: [:]).isEmpty)
    #expect(Self.shape("g", attributes: ["d": "M0 0h1"]).isEmpty)
  }

  @Test("a rectangle's corner takes the other radius where one is left out, held within its side")
  func corners() {
    let rounded = Self.shape("rect", attributes: ["width": "20", "height": "10", "rx": "4"])
    let square = Self.shape("rect", attributes: ["width": "20", "height": "10"])
    let held = shapePath(
      GlyphShape(tag: "rect", attributes: ["width": "20", "height": "10", "rx": "30", "ry": "2"]))

    #expect(rounded.contains { if case .curve = $0 { true } else { false } })
    #expect(!square.contains { if case .curve = $0 { true } else { false } })
    #expect(held?.boundingRect == CGRect(x: 0, y: 0, width: 20, height: 10))
    #expect(
      !Self.shape("rect", attributes: ["width": "20", "height": "10", "rx": "-4"]).contains {
        if case .curve = $0 { true } else { false }
      })
  }

  @Test("a length is a number, in user units or px, and anything else is one left out")
  func lengths() {
    #expect(svgLength(" 12 ") == 12)
    #expect(svgLength("12px") == 12)
    #expect(svgLength("1e2") == 100)
    #expect(svgLength("-.5") == -0.5)
    #expect(svgLength("12em") == nil)
    #expect(svgLength("50%") == nil)
    #expect(svgLength("") == nil)
    #expect(svgPoints("1,2 3 4 5") == [CGPoint(x: 1, y: 2), CGPoint(x: 3, y: 4)])
    #expect(svgPoints("1 2 x 3 4") == [CGPoint(x: 1, y: 2)])
  }

  @Test("every glyph of both bundled sets draws inside its 24-unit box")
  func bundled() {
    for set in [GlyphSet.marker, GlyphSet.control] {
      for (name, markup) in set.markup {
        var bounds = CGRect.null
        for shape in parseGlyph(markup) {
          guard let path = shapePath(shape) else { continue }
          bounds = bounds.union(
            path.applying(svgTransform(shape.attributes["transform"] ?? "")).boundingRect)
        }
        #expect(!bounds.isNull, "\(set.name)/\(name) draws nothing")
        #expect(
          bounds.minX > -0.01 && bounds.minY > -0.01 && bounds.maxX < 24.01
            && bounds.maxY < 24.01, "\(set.name)/\(name): \(bounds)")
      }
    }
  }
}
