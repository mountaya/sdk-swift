#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  public import MountayaGeo
  public import SwiftUI

  /// Glyph draws one glyph of a set, in the `control-fg` token of the tokens around it under the
  /// colour scheme in force unless it is handed a colour, as `sdk-kotlin`'s and `sdk-dart`'s draw
  /// one: a control's role from the control set of the scope around it, or any glyph of the set it
  /// is handed.
  ///
  /// ```swift
  /// Label {
  ///   Text("Zoom in")
  /// } icon: {
  ///   Glyph("zoom-in")
  /// }
  /// Glyph("hut", in: .marker, size: 24, color: .orange, label: "Refuge")
  /// ```
  ///
  /// A glyph handed no set is drawn from the control set of the elements scope SwiftUI's
  /// environment carries (`mountayaScope(_:)`), the bundled control set where no scope states
  /// another, so a host's licensed set reaches its own glyphs as it reaches the controls'. A glyph
  /// handed no colour reads `control-fg` from the tokens SwiftUI's environment carries
  /// (`mountayaTokens(_:)`), under the colour scheme in force, so it follows a host's tokens and
  /// the dark scheme as the controls do.
  ///
  /// The glyph's markup is read into shapes (`parseGlyph(_:)`), never drawn as it was handed over,
  /// and each shape is painted as its set paints it (`glyphPaint(_:in:)`): a stroke set strokes
  /// each shape at its width with round ends, a fill set fills each, and a shape's own fill,
  /// stroke, cap, join and miter limit replace the set's for it alone. A glyph is read once and its
  /// shapes kept for every later drawing of it.
  ///
  /// A glyph the set does not hold, or whose markup draws nothing, is drawn as nothing and takes
  /// no room, as a control draws a glyph its set cannot (`geo.icons.glyph-fallback`). The glyph is
  /// hidden from assistive technologies unless it is given a `label`, for the glyph that is the
  /// control rather than one beside a label of its own.
  public struct Glyph: View {
    /// Ink is what a glyph's shapes are painted in: a colour handed over, the `control-fg` token,
    /// or, for a glyph a view of the elements draws on a face it colours itself, the foreground
    /// style around it.
    enum Ink {
      case color(Color)
      case token
      case foreground
    }

    private let name: String
    private let set: GlyphSet?
    private let size: CGFloat
    private let ink: Ink
    private let label: String?

    @Environment(\.sharedScope) private var scope
    @Environment(\.sharedTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme

    /// Creates a view drawing the glyph `name` of `set`, the control set of the scope around it
    /// where it is nil, in a square `size` points wide, in `color`, the `control-fg` token under
    /// the colour scheme in force where it is nil, named `label` to assistive technologies where it
    /// is given.
    public init(
      _ name: String, in set: GlyphSet? = nil, size: CGFloat = 16, color: Color? = nil,
      label: String? = nil
    ) {
      self.init(name, in: set, size: size, ink: color.map(Ink.color) ?? .token, label: label)
    }

    /// Creates a view drawing the glyph `name` of `set` in `ink`, which the views of the elements
    /// draw their faces' glyphs with in the foreground style they set around them.
    init(_ name: String, in set: GlyphSet?, size: CGFloat, ink: Ink, label: String? = nil) {
      self.name = name
      self.set = set
      self.size = size
      self.ink = ink
      self.label = label
    }

    /// body is the glyph's shapes on a canvas of its size, or nothing where it draws none.
    public var body: some View {
      let drawn = set ?? scope.controlGlyphs
      let figures = glyphFigures(name, in: drawn) ?? []
      if figures.isEmpty {
        EmptyView()
      } else {
        let viewBox = drawn.viewBox
        let painted = shading
        let canvas = Canvas { context, canvasSize in
          let scale = min(canvasSize.width, canvasSize.height) / viewBox
          context.scaleBy(x: scale, y: scale)
          for figure in figures {
            var shape = context
            shape.concatenate(figure.transform)
            if figure.paint.isFilled {
              shape.fill(
                figure.path, with: painted,
                style: FillStyle(eoFill: figure.paint.fillRule == .evenOdd))
            }
            if figure.paint.isStroked {
              shape.stroke(
                figure.path, with: painted,
                style: StrokeStyle(
                  lineWidth: figure.paint.strokeWidth, lineCap: cgLineCap(figure.paint.lineCap),
                  lineJoin: cgLineJoin(figure.paint.lineJoin),
                  miterLimit: figure.paint.miterLimit))
            }
          }
        }
        .frame(width: size, height: size)
        if let label {
          canvas.accessibilityElement().accessibilityLabel(Text(verbatim: label))
            .accessibilityAddTraits(.isImage)
        } else {
          canvas.accessibilityHidden(true)
        }
      }
    }

    /// shading is what the glyph's shapes are painted with: its colour, the `control-fg` token
    /// under the colour scheme in force, or the foreground style around it.
    private var shading: GraphicsContext.Shading {
      switch ink {
      case .color(let color): .color(color)
      case .token: .color(tokenColor(tokens.controlFg, in: themeScheme(colorScheme)))
      case .foreground: .foreground
      }
    }
  }
#endif
