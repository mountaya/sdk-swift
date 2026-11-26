#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  internal import UIKit

  /// stripePatternImage draws the stripe tile `pattern` describes, the image a stretch's pattern
  /// repeats along it (`map.icons.stripe-pattern`): the tile filled with its ground, where it has
  /// one, and each stripe stroked along its segment in its colour and width, with its ends, the
  /// halves that run past the tile's edges cut at them.
  ///
  /// The image is the tile's size in points, drawn at the screen's density, and never a template
  /// MapLibre would recolour.
  func stripePatternImage(_ pattern: StripePattern) -> UIImage {
    let format = UIGraphicsImageRendererFormat.preferred()
    format.opaque = false
    format.preferredRange = .standard
    let side = CGFloat(pattern.size)
    let image = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format)
      .image { drawn in
        let context = drawn.cgContext
        if let ground = pattern.ground.flatMap({ uiColor($0) }) {
          context.setFillColor(ground.cgColor)
          context.fill(CGRect(x: 0, y: 0, width: side, height: side))
        }
        guard let color = uiColor(pattern.color) else { return }
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(pattern.width)
        context.setLineCap(cgLineCap(pattern.lineCap))
        for segment in pattern.segments where segment.count == 2 {
          let (from, to) = (segment[0], segment[1])
          guard from.count == 2, to.count == 2 else { continue }
          context.move(to: CGPoint(x: from[0], y: from[1]))
          context.addLine(to: CGPoint(x: to[0], y: to[1]))
        }
        context.strokePath()
      }
    return image.withRenderingMode(.alwaysOriginal)
  }
#endif
