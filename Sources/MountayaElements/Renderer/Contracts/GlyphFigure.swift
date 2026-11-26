#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import MountayaGeo
  internal import SwiftUI

  /// GlyphFigure is one shape of a glyph as a renderer draws it: its outline in the units of its
  /// set's box, the transform it is drawn through, and its paint, the current colour standing for
  /// whatever colour the surface draws the glyph in.
  ///
  /// The transform is applied as the shape is drawn, never to the outline, so a stroke's width
  /// scales with the shape as SVG scales it.
  struct GlyphFigure: Sendable {
    /// path is the shape's outline, before its transform.
    let path: Path
    /// transform is the transform the shape is drawn through.
    let transform: CGAffineTransform
    /// paint is how the shape is filled and stroked (`geo.icons.glyph-paint`).
    let paint: ShapePaint
  }
#endif
