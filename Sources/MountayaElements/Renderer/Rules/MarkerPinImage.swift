#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import MountayaGeo
  internal import UIKit

  /// markerPinImage draws the pin `pin` describes, how a marker given no view of its own is shown
  /// (`map.marker.pin`): a disc its diameter across in its fill, `accent` where it states none, at
  /// its opacity, its
  /// ring drawn inside that diameter, and at its centre its glyph, drawn from `set` and fitted to
  /// the glyph's square, or its dot.
  ///
  /// The image is the pin's diameter in points, drawn at the screen's density, so a pin is the same
  /// size on every screen, and it is never a template UIKit would recolour. A fill that is no CSS
  /// hexadecimal colour fills no disc, as a marker sprite's does, and the ring and the centre are
  /// drawn all the same. The glyph is painted as its set paints it, each figure filled then stroked
  /// at the set's width scaled with the glyph.
  func markerPinImage(_ pin: MarkerPin, accent: HexColor, in set: GlyphSet) -> UIImage {
    let format = UIGraphicsImageRendererFormat.preferred()
    format.opaque = false
    format.preferredRange = .standard
    let side = CGFloat(pin.diameter)
    let image = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format)
      .image { drawn in
        let context = drawn.cgContext
        let disc = CGRect(x: 0, y: 0, width: side, height: side)
        let fill = pin.fill.map { uiColor($0) } ?? uiColor(accent.hex, opacity: accent.opacity)
        if let fill {
          context.setFillColor(fill.cgColor)
          context.fillEllipse(in: disc)
        }
        // The ring lies within the diameter, as a border drawn inside its box.
        let ringWidth = CGFloat(pin.ringWidth)
        if ringWidth > 0, let ring = uiColor(pin.ringColor) {
          context.setStrokeColor(ring.cgColor)
          context.setLineWidth(ringWidth)
          context.strokeEllipse(in: disc.insetBy(dx: ringWidth / 2, dy: ringWidth / 2))
        }
        switch pin.centre {
        case .glyph(let glyph, let size, let color):
          guard let color = uiColor(color), let figures = glyphFigures(glyph, in: set) else {
            return
          }
          let square = CGFloat(size)
          context.translateBy(x: (side - square) / 2, y: (side - square) / 2)
          context.scaleBy(x: square / CGFloat(set.viewBox), y: square / CGFloat(set.viewBox))
          draw(figures, in: context, color: color.cgColor)
        case .dot(let size, let color):
          guard let color = uiColor(color) else { return }
          let dot = CGFloat(size)
          context.setFillColor(color.cgColor)
          context.fillEllipse(
            in: CGRect(x: (side - dot) / 2, y: (side - dot) / 2, width: dot, height: dot))
        }
      }
    return image.withRenderingMode(.alwaysOriginal)
  }
#endif
