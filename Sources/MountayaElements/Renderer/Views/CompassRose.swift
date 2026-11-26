#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import MountayaGeo
  internal import SwiftUI

  /// CompassRose draws Mountaya's compass rose, the contract's `compass-rose` drawing, in a square
  /// of its size: its disc in `control-bg` and its letter in `control-fg` under the scheme in
  /// force, its needle in the colour the drawing fixes, turned against `bearing` so it keeps
  /// pointing north. A bearing of 90 turns the map clockwise, so the rose turns anticlockwise.
  struct CompassRose: View {
    let bearing: Double
    var size: CGFloat = 34

    @Environment(\.sharedTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
      let scheme = themeScheme(colorScheme)
      let tokens = tokens
      Canvas { context, canvasSize in
        guard let drawing = GlyphDrawing.artwork["compass-rose"], drawing.viewBox.count == 4,
          drawing.viewBox[2] > 0, drawing.viewBox[3] > 0
        else { return }
        let box = drawing.viewBox
        let scale = min(canvasSize.width / box[2], canvasSize.height / box[3])
        context.scaleBy(x: scale, y: scale)
        context.translateBy(x: -box[0], y: -box[1])
        for shape in drawing.shapes {
          for parsed in parseGlyph(shape.markup) {
            guard let path = shapePath(parsed) else { continue }
            var drawn = context
            drawn.concatenate(svgTransform(parsed.attributes["transform"] ?? ""))
            if let fill = shape.fill {
              drawn.fill(path, with: .color(Self.color(fill, tokens: tokens, scheme: scheme)))
            }
            if let stroke = shape.stroke, let width = shape.strokeWidth {
              drawn.stroke(
                path, with: .color(Self.color(stroke, tokens: tokens, scheme: scheme)),
                lineWidth: width)
            }
          }
        }
      }
      .frame(width: size, height: size)
      .rotationEffect(.degrees(-bearing))
      .accessibilityHidden(true)
    }

    /// color is the colour `paint` reads: the one the drawing fixes, or its token's under
    /// `scheme`, at the paint's opacity.
    static func color(_ paint: GlyphDrawing.Paint, tokens: SharedTokens, scheme: ThemeScheme)
      -> Color
    {
      switch paint {
      case .color(let color):
        return hexColor(color)
      case .token(let path, let opacity):
        var value = themeTokenValue(tokens.value[keyPath: path], in: scheme)
        value.opacity *= opacity
        return hexColor(value)
      case .linear(let gradient):
        // The rose fills no shape with a gradient; one that did reads its first stop.
        return gradient.stops.first.map { hexColor($0.color) } ?? .clear
      }
    }
  }
#endif
