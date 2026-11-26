#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import MountayaGeo
  internal import UIKit

  /// markerSpriteImage draws the marker sprite `sprite` describes, its glyph's `figures` fitted to
  /// the square at its centre, as a colour image MapLibre takes as it is (`map.icons.marker-sprite`).
  ///
  /// The image is the sprite's size in points, drawn at the screen's density, so one sprite is the
  /// same size on every screen, and it is never a template MapLibre would recolour. The disc is
  /// filled with the feature's colour and stroked with its border, centred on its edge; a colour
  /// that is no CSS hexadecimal colour fills no disc. The glyph is drawn over it in the glyph's
  /// colour, each figure filled then stroked as its paint says, at the set's width scaled with the
  /// glyph.
  func markerSpriteImage(_ sprite: MarkerSprite, figures: [GlyphFigure]) -> UIImage {
    let format = UIGraphicsImageRendererFormat.preferred()
    format.opaque = false
    format.preferredRange = .standard
    let side = CGFloat(sprite.size)
    let image = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format)
      .image { drawn in
        let context = drawn.cgContext
        let disc = sprite.disc
        let center = CGPoint(x: disc.center.first ?? 0, y: disc.center.dropFirst().first ?? 0)
        let bounds = CGRect(
          x: center.x - disc.radius, y: center.y - disc.radius, width: 2 * disc.radius,
          height: 2 * disc.radius)
        if let fill = uiColor(disc.fill) {
          context.setFillColor(fill.cgColor)
          context.fillEllipse(in: bounds)
        }
        if let border = uiColor(disc.borderColor) {
          context.setStrokeColor(border.cgColor)
          context.setLineWidth(disc.borderWidth)
          context.strokeEllipse(in: bounds)
        }
        guard let color = uiColor(sprite.glyph.color) else { return }
        context.translateBy(x: sprite.glyph.offset, y: sprite.glyph.offset)
        context.scaleBy(x: sprite.glyph.scale, y: sprite.glyph.scale)
        draw(figures, in: context, color: color.cgColor)
      }
    return image.withRenderingMode(.alwaysOriginal)
  }
#endif
