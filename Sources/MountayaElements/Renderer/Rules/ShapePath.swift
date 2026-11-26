#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import Foundation
  import MountayaGeo
  internal import SwiftUI

  /// shapePath is the outline of one shape of a glyph, as SVG draws it, in the units of its set's
  /// box and before its transform, which a renderer applies as it draws so a stroke's width scales
  /// with the shape as SVG scales it; nil where the shape draws nothing.
  ///
  /// A `path` is its path data; a `circle`, an `ellipse` and a `rect` are the shapes SVG 2 lays
  /// them out as, a radius left out of an ellipse or a rectangle's corner taking the other's and a
  /// corner held within half the rectangle's side; a `line` is its two ends; a `polyline` and a
  /// `polygon` their points, a polygon closed. A shape of no size, a circle of no radius or a
  /// rectangle of no width, draws nothing. A length is a number, its unit `px` where it states
  /// one, and a length no number reads as one left out. The geometry is SVG's own grammar, read
  /// here since no Apple framework reads it: the contract parses a glyph into shapes and stops at
  /// their attributes (`geo.icons.glyph-parse`).
  func shapePath(_ shape: GlyphShape) -> Path? {
    func length(_ name: String) -> Double? {
      shape.attributes[name].flatMap(svgLength)
    }
    switch shape.tag {
    case "path":
      return shape.attributes["d"].map(svgPathData)
    case "circle":
      guard let r = length("r"), r > 0 else { return nil }
      let (cx, cy) = (length("cx") ?? 0, length("cy") ?? 0)
      return Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r))
    case "ellipse":
      guard let rx = length("rx") ?? length("ry"), let ry = length("ry") ?? length("rx"),
        rx > 0, ry > 0
      else { return nil }
      let (cx, cy) = (length("cx") ?? 0, length("cy") ?? 0)
      return Path(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: 2 * rx, height: 2 * ry))
    case "rect":
      guard let width = length("width"), let height = length("height"), width > 0, height > 0
      else { return nil }
      let rect = CGRect(x: length("x") ?? 0, y: length("y") ?? 0, width: width, height: height)
      // A corner a radius states below 0 is no corner; one left out takes the other's.
      let rx = length("rx").flatMap { $0 >= 0 ? $0 : nil }
      let ry = length("ry").flatMap { $0 >= 0 ? $0 : nil }
      let cornerX = min(rx ?? ry ?? 0, width / 2)
      let cornerY = min(ry ?? rx ?? 0, height / 2)
      guard cornerX > 0, cornerY > 0 else { return Path(rect) }
      return Path(
        roundedRect: rect, cornerSize: CGSize(width: cornerX, height: cornerY), style: .circular)
    case "line":
      var path = Path()
      path.move(to: CGPoint(x: length("x1") ?? 0, y: length("y1") ?? 0))
      path.addLine(to: CGPoint(x: length("x2") ?? 0, y: length("y2") ?? 0))
      return path
    case "polyline", "polygon":
      let points = svgPoints(shape.attributes["points"] ?? "")
      guard let first = points.first else { return nil }
      var path = Path()
      path.move(to: first)
      for point in points.dropFirst() {
        path.addLine(to: point)
      }
      if shape.tag == "polygon" {
        path.closeSubpath()
      }
      return path
    default:
      return nil
    }
  }

  /// svgLength reads a length as a glyph's geometry states one: a number, past the white space at
  /// its ends, in user units or in `px`, which are the same; nil for anything else.
  func svgLength(_ written: String) -> Double? {
    var scanner = SVGScanner(written)
    scanner.skipWhiteSpace()
    guard let number = scanner.number() else { return nil }
    _ = scanner.skip("px")
    scanner.skipWhiteSpace()
    return scanner.isAtEnd ? number : nil
  }

  /// svgPoints reads a polyline's or a polygon's points, coordinates separated by white space or a
  /// comma, up to the first that is no number: an odd coordinate left over is dropped, as SVG
  /// draws a list in error up to its error.
  func svgPoints(_ written: String) -> [CGPoint] {
    var scanner = SVGScanner(written)
    var points: [CGPoint] = []
    scanner.skipWhiteSpace()
    while let x = scanner.number() {
      scanner.skipSeparator()
      guard let y = scanner.number() else { break }
      points.append(CGPoint(x: x, y: y))
      scanner.skipSeparator()
    }
    return points
  }

  /// svgPathData is the outline SVG path data `data` draws, up to the command holding its first
  /// error, as SVG draws a path in error: data that opens with no move draws nothing.
  ///
  /// Every command of SVG 1.1 is read, absolute and relative: a move, whose further pairs are
  /// lines, a line, a horizontal and a vertical line, a cubic and a quadratic curve and their
  /// smooth forms, which reflect the control point of the curve before them where it is one of
  /// theirs, an elliptical arc and a close. A command repeats over further arguments without being
  /// written again. A number is SVG's: a sign, digits with at most one decimal point and an
  /// exponent, two numbers written with nothing between them where the second's sign or point
  /// ends the first; an arc's flags are single digits, written with nothing between them or not.
  /// An arc is drawn as cubic curves of a quarter turn at most, its radii scaled up where they
  /// cannot reach its end and taken without their sign, a line where a radius is 0, and nothing
  /// where it ends where it starts. A path drawn after a close starts again where the closed one
  /// started.
  func svgPathData(_ data: String) -> Path {
    var scanner = SVGScanner(data)
    var path = Path()
    var current = CGPoint.zero
    var start = CGPoint.zero
    // The second control point of the cubic curve, or the control point of the quadratic curve,
    // drawn last, which a smooth curve after it reflects.
    var lastCubic: CGPoint?
    var lastQuadratic: CGPoint?
    var command: UInt8?
    var moved = false
    var closed = false

    while true {
      scanner.skipSeparator()
      guard !scanner.isAtEnd else { break }
      if let letter = scanner.command() {
        command = letter
      } else if let repeated = command, repeated | 0x20 != UInt8(ascii: "z") {
        // A further argument repeats the command, a move's as a line.
        switch repeated {
        case UInt8(ascii: "M"): command = UInt8(ascii: "L")
        case UInt8(ascii: "m"): command = UInt8(ascii: "l")
        default: command = repeated
        }
      } else {
        break
      }
      guard let letter = command, moved || letter | 0x20 == UInt8(ascii: "m") else { break }
      let relative = letter >= UInt8(ascii: "a")
      let origin = current
      func point(_ pair: (Double, Double)) -> CGPoint {
        relative
          ? CGPoint(x: origin.x + pair.0, y: origin.y + pair.1) : CGPoint(x: pair.0, y: pair.1)
      }
      var cubic: CGPoint?
      var quadratic: CGPoint?
      // The segment the command draws, from the current point, added once all of it is read.
      var segment = Path()
      segment.move(to: origin)
      switch letter | 0x20 {
      case UInt8(ascii: "m"):
        guard let end = scanner.nextPair().map(point) else { return path }
        path.move(to: end)
        current = end
        start = end
        moved = true
        closed = false
        lastCubic = nil
        lastQuadratic = nil
        continue
      case UInt8(ascii: "z"):
        path.closeSubpath()
        current = start
        closed = true
        lastCubic = nil
        lastQuadratic = nil
        continue
      case UInt8(ascii: "l"):
        guard let end = scanner.nextPair().map(point) else { return path }
        segment.addLine(to: end)
        current = end
      case UInt8(ascii: "h"):
        guard let x = scanner.nextNumber() else { return path }
        current = CGPoint(x: relative ? origin.x + x : x, y: origin.y)
        segment.addLine(to: current)
      case UInt8(ascii: "v"):
        guard let y = scanner.nextNumber() else { return path }
        current = CGPoint(x: origin.x, y: relative ? origin.y + y : y)
        segment.addLine(to: current)
      case UInt8(ascii: "c"):
        guard let control1 = scanner.nextPair().map(point),
          let control2 = scanner.nextPair().map(point), let end = scanner.nextPair().map(point)
        else { return path }
        segment.addCurve(to: end, control1: control1, control2: control2)
        cubic = control2
        current = end
      case UInt8(ascii: "s"):
        guard let control2 = scanner.nextPair().map(point), let end = scanner.nextPair().map(point)
        else { return path }
        let control1 = lastCubic.map { reflected($0, around: origin) } ?? origin
        segment.addCurve(to: end, control1: control1, control2: control2)
        cubic = control2
        current = end
      case UInt8(ascii: "q"):
        guard let control = scanner.nextPair().map(point), let end = scanner.nextPair().map(point)
        else { return path }
        segment.addQuadCurve(to: end, control: control)
        quadratic = control
        current = end
      case UInt8(ascii: "t"):
        guard let end = scanner.nextPair().map(point) else { return path }
        let control = lastQuadratic.map { reflected($0, around: origin) } ?? origin
        segment.addQuadCurve(to: end, control: control)
        quadratic = control
        current = end
      case UInt8(ascii: "a"):
        guard let arc = scanner.nextArc() else { return path }
        let end = point(arc.end)
        addArc(
          to: &segment, from: origin, to: end, radii: (abs(arc.rx), abs(arc.ry)),
          rotation: arc.rotation, largeArc: arc.largeArc, sweep: arc.sweep)
        current = end
      default:
        return path
      }
      // A drawing command after a close starts a path where the closed one started.
      if closed {
        path.move(to: start)
        closed = false
      }
      segment.forEach { element in
        switch element {
        case .line(let to): path.addLine(to: to)
        case .quadCurve(let to, let control): path.addQuadCurve(to: to, control: control)
        case .curve(let to, let control1, let control2):
          path.addCurve(to: to, control1: control1, control2: control2)
        case .move, .closeSubpath: break
        }
      }
      lastCubic = cubic
      lastQuadratic = quadratic
    }
    return path
  }

  /// reflected is `point` reflected through `center`.
  private func reflected(_ point: CGPoint, around center: CGPoint) -> CGPoint {
    CGPoint(x: 2 * center.x - point.x, y: 2 * center.y - point.y)
  }

  /// addArc adds to `path` the elliptical arc from `start` to `end` as SVG lays one out (SVG 1.1,
  /// appendix F.6), as cubic curves of a quarter turn at most.
  private func addArc(
    to path: inout Path, from start: CGPoint, to end: CGPoint, radii: (Double, Double),
    rotation degrees: Double, largeArc: Bool, sweep: Bool
  ) {
    guard start != end else { return }
    var (rx, ry) = radii
    guard rx > 0, ry > 0 else {
      path.addLine(to: end)
      return
    }
    let phi = degrees * .pi / 180
    let (cosPhi, sinPhi) = (cos(phi), sin(phi))
    // The midpoint between the ends, in the ellipse's own axes.
    let dx = (start.x - end.x) / 2
    let dy = (start.y - end.y) / 2
    let x1 = cosPhi * dx + sinPhi * dy
    let y1 = -sinPhi * dx + cosPhi * dy
    // Radii too small to reach the end are scaled up until they do.
    let lambda = (x1 * x1) / (rx * rx) + (y1 * y1) / (ry * ry)
    if lambda > 1 {
      rx *= lambda.squareRoot()
      ry *= lambda.squareRoot()
    }
    let numerator = rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1
    let denominator = rx * rx * y1 * y1 + ry * ry * x1 * x1
    let coefficient =
      (largeArc == sweep ? -1 : 1) * (max(numerator, 0) / denominator).squareRoot()
    let centerX1 = coefficient * rx * y1 / ry
    let centerY1 = -coefficient * ry * x1 / rx
    let center = CGPoint(
      x: cosPhi * centerX1 - sinPhi * centerY1 + (start.x + end.x) / 2,
      y: sinPhi * centerX1 + cosPhi * centerY1 + (start.y + end.y) / 2)
    let startAngle = atan2((y1 - centerY1) / ry, (x1 - centerX1) / rx)
    let endAngle = atan2((-y1 - centerY1) / ry, (-x1 - centerX1) / rx)
    var sweepAngle = endAngle - startAngle
    if sweep, sweepAngle < 0 {
      sweepAngle += 2 * .pi
    } else if !sweep, sweepAngle > 0 {
      sweepAngle -= 2 * .pi
    }
    // A point of the unit circle at `angle`, on the ellipse.
    func onEllipse(x: Double, y: Double) -> CGPoint {
      CGPoint(
        x: center.x + cosPhi * rx * x - sinPhi * ry * y,
        y: center.y + sinPhi * rx * x + cosPhi * ry * y)
    }
    let pieces = max(1, Int((abs(sweepAngle) / (.pi / 2)).rounded(.up)))
    let step = sweepAngle / Double(pieces)
    let handle = 4.0 / 3.0 * tan(step / 4)
    var angle = startAngle
    for piece in 0..<pieces {
      let next = angle + step
      let control1 = onEllipse(
        x: cos(angle) - handle * sin(angle), y: sin(angle) + handle * cos(angle))
      let control2 = onEllipse(x: cos(next) + handle * sin(next), y: sin(next) - handle * cos(next))
      // The last piece ends where the arc does, never where rounding leaves it.
      let to = piece == pieces - 1 ? end : onEllipse(x: cos(next), y: sin(next))
      path.addCurve(to: to, control1: control1, control2: control2)
      angle = next
    }
  }

  /// SVGScanner reads the numbers, flags and command letters of SVG's attribute grammars, byte by
  /// byte, since every character they hold is ASCII.
  struct SVGScanner {
    private let bytes: [UInt8]
    private var at = 0

    init(_ text: String) {
      bytes = Array(text.utf8)
    }

    /// isAtEnd is true where every byte was read.
    var isAtEnd: Bool { at >= bytes.count }

    /// skipWhiteSpace reads past SVG's white space: a space, a tab, a line feed, a form feed and
    /// a carriage return.
    mutating func skipWhiteSpace() {
      while at < bytes.count, [0x20, 0x09, 0x0A, 0x0C, 0x0D].contains(bytes[at]) {
        at += 1
      }
    }

    /// skipSeparator reads past white space with at most one comma in it, and tells whether it
    /// read anything.
    @discardableResult
    mutating func skipSeparator() -> Bool {
      let before = at
      skipWhiteSpace()
      if at < bytes.count, bytes[at] == UInt8(ascii: ",") {
        at += 1
        skipWhiteSpace()
      }
      return at != before
    }

    /// skip reads past `word` where the bytes spell it next, and tells whether they did.
    mutating func skip(_ word: String) -> Bool {
      let spelled = Array(word.utf8)
      guard at + spelled.count <= bytes.count, Array(bytes[at..<(at + spelled.count)]) == spelled
      else { return false }
      at += spelled.count
      return true
    }

    /// command reads the letter of a path command where one stands next.
    mutating func command() -> UInt8? {
      guard at < bytes.count, Array("MmZzLlHhVvCcSsQqTtAa".utf8).contains(bytes[at]) else {
        return nil
      }
      defer { at += 1 }
      return bytes[at]
    }

    /// flag reads an arc's flag, `0` or `1`, where one stands next.
    mutating func flag() -> Bool? {
      guard at < bytes.count, bytes[at] == UInt8(ascii: "0") || bytes[at] == UInt8(ascii: "1")
      else { return nil }
      defer { at += 1 }
      return bytes[at] == UInt8(ascii: "1")
    }

    /// nextNumber reads a number past the separator before it, where one stands next.
    mutating func nextNumber() -> Double? {
      skipSeparator()
      return number()
    }

    /// nextPair reads two numbers past the separator before each.
    mutating func nextPair() -> (Double, Double)? {
      guard let x = nextNumber(), let y = nextNumber() else { return nil }
      return (x, y)
    }

    /// nextArc reads an arc's arguments past the separator before each: its radii, the rotation of
    /// its axes in degrees, its two flags and its end.
    mutating func nextArc()
      -> (
        rx: Double, ry: Double, rotation: Double, largeArc: Bool, sweep: Bool, end: (Double, Double)
      )?
    {
      guard let rx = nextNumber(), let ry = nextNumber(), let rotation = nextNumber() else {
        return nil
      }
      skipSeparator()
      guard let largeArc = flag() else { return nil }
      skipSeparator()
      guard let sweep = flag(), let end = nextPair() else { return nil }
      return (rx, ry, rotation, largeArc, sweep, end)
    }

    /// number reads a number where one stands next: a sign, digits with at most one decimal point
    /// and a digit on one side of it at least, then an exponent where `e` is followed by digits.
    /// The bytes stay unread where no number stands next.
    mutating func number() -> Double? {
      let from = at
      var cursor = at
      func digits() -> Int {
        let first = cursor
        while cursor < bytes.count, bytes[cursor] >= UInt8(ascii: "0"),
          bytes[cursor] <= UInt8(ascii: "9")
        {
          cursor += 1
        }
        return cursor - first
      }
      if cursor < bytes.count,
        bytes[cursor] == UInt8(ascii: "+") || bytes[cursor] == UInt8(ascii: "-")
      {
        cursor += 1
      }
      var counted = digits()
      if cursor < bytes.count, bytes[cursor] == UInt8(ascii: ".") {
        cursor += 1
        counted += digits()
      }
      guard counted > 0 else { return nil }
      if cursor < bytes.count, bytes[cursor] | 0x20 == UInt8(ascii: "e") {
        let mantissa = cursor
        cursor += 1
        if cursor < bytes.count,
          bytes[cursor] == UInt8(ascii: "+") || bytes[cursor] == UInt8(ascii: "-")
        {
          cursor += 1
        }
        if digits() == 0 {
          cursor = mantissa
        }
      }
      guard let text = String(bytes: bytes[from..<cursor], encoding: .ascii),
        let number = Double(text), number.isFinite
      else { return nil }
      at = cursor
      return number
    }
  }
#endif
