#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import MountayaGeo
  internal import SwiftUI

  /// glyphFigures is the glyph `glyph` of `set` as a renderer draws it, a figure for each of its
  /// shapes that draws anything, in drawing order, or nil where the set does not hold the glyph.
  ///
  /// The markup is read once, by `readGlyphFigures(_:in:)`, and the figures kept for every later
  /// drawing of the glyph by the process's `GlyphFigureCache`, so a control drawn again, a pin and
  /// a sprite of one glyph read nothing again.
  func glyphFigures(_ glyph: String, in set: GlyphSet) -> [GlyphFigure]? {
    GlyphFigureCache.shared.figures(glyph, in: set)
  }

  /// readGlyphFigures reads a glyph's `markup` into the figures a renderer draws, as `set` paints
  /// them: a figure for each of its shapes that draws anything, in drawing order.
  ///
  /// The markup is read through `parseGlyph(_:)`, never drawn as it was handed over, so a set built
  /// from a source its host does not control draws no element and no attribute the glyph's
  /// allowlist does not keep. Each shape is painted as its set paints it, its own fill, stroke,
  /// cap, join and miter limit replacing the set's for it alone (`glyphPaint(_:in:)`).
  func readGlyphFigures(_ markup: String, in set: GlyphSet) -> [GlyphFigure] {
    parseGlyph(markup).compactMap { shape in
      shapePath(shape).map { path in
        GlyphFigure(
          path: path, transform: svgTransform(shape.attributes["transform"] ?? ""),
          paint: glyphPaint(shape, in: set))
      }
    }
  }

  /// draw draws `figures` in `context`, each filled then stroked as its paint says, in `color`.
  ///
  /// The context is in the units of the set's box, its transform placing the box where the glyph
  /// is drawn; each figure is drawn through its own transform on top of it.
  func draw(_ figures: [GlyphFigure], in context: CGContext, color: CGColor) {
    for figure in figures {
      context.saveGState()
      context.concatenate(figure.transform)
      let outline = figure.path.cgPath
      if figure.paint.isFilled {
        context.addPath(outline)
        context.setFillColor(color)
        context.fillPath(using: figure.paint.fillRule == .evenOdd ? .evenOdd : .winding)
      }
      if figure.paint.isStroked {
        context.addPath(outline)
        context.setStrokeColor(color)
        context.setLineWidth(figure.paint.strokeWidth)
        context.setLineCap(cgLineCap(figure.paint.lineCap))
        context.setLineJoin(cgLineJoin(figure.paint.lineJoin))
        context.setMiterLimit(figure.paint.miterLimit)
        context.strokePath()
      }
      context.restoreGState()
    }
  }

  /// cgLineCap is the cap CoreGraphics draws for an SVG cap.
  func cgLineCap(_ cap: ShapePaint.LineCap) -> CGLineCap {
    switch cap {
    case .butt: .butt
    case .round: .round
    case .square: .square
    }
  }

  /// cgLineJoin is the join CoreGraphics draws for an SVG join: `arcs` and `miter-clip`, which it
  /// draws none of, as a miter, as SVG asks a renderer that draws neither to.
  func cgLineJoin(_ join: ShapePaint.LineJoin) -> CGLineJoin {
    switch join {
    case .arcs, .miter, .miterClip: .miter
    case .bevel: .bevel
    case .round: .round
    }
  }
#endif
