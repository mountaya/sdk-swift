#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import Foundation
  internal import SwiftUI

  /// svgTransform is the transform an SVG transform list `list` states, each of its transforms
  /// applied to a point in turn from the last to the first, as SVG nests them: a group's transform,
  /// which `parseGlyph(_:)` folds before a shape's own, places the shape after the shape's own has.
  ///
  /// It reads `matrix`, `translate`, `scale`, `rotate`, about the origin or a centre it states,
  /// `skewX` and `skewY`, each angle in degrees, separated by white space or a comma, and answers
  /// no transform at all for a list that holds anything else, as a renderer reads a list in error:
  /// no part of it applies. An empty list is no transform.
  func svgTransform(_ list: String) -> CGAffineTransform {
    var scanner = SVGScanner(list)
    var transform = CGAffineTransform.identity
    scanner.skipWhiteSpace()
    while !scanner.isAtEnd {
      guard let next = nextTransform(&scanner) else { return .identity }
      // The later transform applies to a point first.
      transform = next.concatenating(transform)
      scanner.skipSeparator()
    }
    return transform
  }

  /// The transforms of a list, each with the arguments it takes at least and at most.
  private let transformArguments: [(name: String, least: Int, most: Int)] = [
    ("matrix", 6, 6), ("translate", 1, 2), ("scale", 1, 2), ("rotate", 1, 3), ("skewX", 1, 1),
    ("skewY", 1, 1),
  ]

  /// nextTransform reads one transform of a list, its name, white space, and its arguments in
  /// parentheses, or nil where none stands next.
  private func nextTransform(_ scanner: inout SVGScanner) -> CGAffineTransform? {
    guard let named = transformArguments.first(where: { scanner.skip($0.name) }) else {
      return nil
    }
    scanner.skipWhiteSpace()
    guard scanner.skip("(") else { return nil }
    scanner.skipWhiteSpace()
    var arguments: [Double] = []
    while arguments.count < named.most {
      if !arguments.isEmpty {
        scanner.skipSeparator()
      }
      guard let number = scanner.number() else { break }
      arguments.append(number)
    }
    scanner.skipWhiteSpace()
    guard scanner.skip(")"), arguments.count >= named.least,
      named.name != "rotate" || arguments.count != 2
    else { return nil }
    let radians = arguments[0] * .pi / 180
    switch named.name {
    case "matrix":
      return CGAffineTransform(
        a: arguments[0], b: arguments[1], c: arguments[2], d: arguments[3], tx: arguments[4],
        ty: arguments[5])
    case "translate":
      return CGAffineTransform(
        translationX: arguments[0], y: arguments.count > 1 ? arguments[1] : 0)
    case "scale":
      return CGAffineTransform(
        scaleX: arguments[0], y: arguments.count > 1 ? arguments[1] : arguments[0])
    case "rotate":
      let rotation = CGAffineTransform(rotationAngle: radians)
      guard arguments.count == 3 else { return rotation }
      // About a centre: moved to the origin, turned, and moved back.
      return CGAffineTransform(translationX: -arguments[1], y: -arguments[2])
        .concatenating(rotation)
        .concatenating(CGAffineTransform(translationX: arguments[1], y: arguments[2]))
    case "skewX":
      return CGAffineTransform(a: 1, b: 0, c: tan(radians), d: 1, tx: 0, ty: 0)
    default:
      return CGAffineTransform(a: 1, b: tan(radians), c: 0, d: 1, tx: 0, ty: 0)
    }
  }
#endif
