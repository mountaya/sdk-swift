#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import Foundation
  import MountayaGeo
  internal import SwiftUI
  internal import UIKit

  /// WatermarkLink is the Mountaya watermark a map draws over its canvas
  /// (`geo.organization.watermark`): nothing while the read of its organization waits within one
  /// attempt's budget or once it answers white label, and otherwise the glyph table's `watermark`
  /// drawing in the frame `watermarkOf(_:language:page:)` answers, measured from the top-left
  /// corner of the map's safe area, the part of the map the device leaves visible, its top-left
  /// corner 4 points outside that corner, and clipped to the map it is laid over, so a map drawn
  /// full bleed shows it below the status bar and beside a notch or a cutout, and its empty margin
  /// and its shadow draw over nothing of the app's. The corner is the one the reader sees at the
  /// top left, in a layout that runs right to left too, as `sdk/SPEC.md` §15 places it. A press opens Mountaya's site, in the scope's
  /// language, in the device's browser, through the system's own opener, `opener`, which no
  /// environment of the app's replaces. Assistive technologies read it as a link labelled
  /// `watermark.label`.
  ///
  /// A map an app draws is in no browser document, so no page's origin is handed the rule, and no
  /// argument of its own could take the mark off. It reads the engine's read, the map's safe area
  /// and the scope alone, so SwiftUI draws it again only when one changes, never per frame of the
  /// map.
  struct WatermarkLink: View {
    let engine: MapEngine

    @ViewScope private var scope: ElementsScope

    init(engine: MapEngine) {
      self.engine = engine
      _scope = ViewScope(strings: nil)
    }

    /// opener is how a press opens the mark's link: the system's own, outside the app, unless a test
    /// of this package states another.
    static var opener: @MainActor (URL) -> Void = { url in
      UIApplication.shared.open(url)
    }

    var body: some View {
      // The mark is laid over a ground that takes the map's size and no touch, and clipped to it.
      Color.clear
        .allowsHitTesting(false)
        .overlay(alignment: .topLeading) {
          if let mark = watermarkOf(engine.organizationRead, language: scope.language) {
            let frame = watermarkFrame(mark, safeArea: engine.safeArea)
            Button {
              Self.press(mark.href)
            } label: {
              WatermarkDrawing()
                .frame(width: mark.width, height: mark.height)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .offset(x: frame.x, y: frame.y)
            .accessibilityLabel(Text(verbatim: scope.word(mark.label)))
            .accessibilityAddTraits(.isLink)
            .accessibilityRemoveTraits(.isButton)
          }
        }
        .clipped()
        // The map's safe area is measured from its left edge whatever the reader's direction.
        .environment(\.layoutDirection, .leftToRight)
    }

    /// press opens the mark's link, `href`, through `opener`, as a press on the mark does.
    static func press(_ href: String) {
      guard let url = URL(string: href) else { return }
      opener(url)
    }
  }

  /// WatermarkDrawing draws the glyph table's `watermark` drawing in the frame it is given, from
  /// its path data, its gradients, its opacity and its drop shadow, and clipped to its box. Its
  /// paths are read once for the process, so drawing it again reads no markup.
  struct WatermarkDrawing: View {
    /// paths is each shape of the drawing read into its paths, in drawing order.
    static let paths: [[Path]] = (GlyphDrawing.artwork[watermarkDrawing]?.shapes ?? []).map {
      shape in parseGlyph(shape.markup).compactMap { shapePath($0) }
    }

    var body: some View {
      Canvas { context, size in
        guard let drawing = GlyphDrawing.artwork[watermarkDrawing], drawing.viewBox.count == 4,
          drawing.viewBox[2] > 0, drawing.viewBox[3] > 0
        else { return }
        let box = drawing.viewBox
        let scale = min(size.width / box[2], size.height / box[3])
        context.clip(to: Path(CGRect(origin: .zero, size: size)))
        context.opacity = drawing.opacity
        if let shadow = drawing.shadow {
          // SVG's Gaussian of standard deviation `blur` spreads about twice that far, the reach
          // a SwiftUI shadow's radius states.
          context.addFilter(
            .shadow(
              color: hexColor(shadow.color), radius: shadow.blur * 2 * scale,
              x: shadow.dx * scale, y: shadow.dy * scale))
        }
        context.drawLayer { layer in
          layer.scaleBy(x: scale, y: scale)
          layer.translateBy(x: -box[0], y: -box[1])
          for (shape, paths) in zip(drawing.shapes, Self.paths) {
            guard let fill = shape.fill else { continue }
            for path in paths {
              layer.fill(path, with: Self.shading(fill))
            }
          }
        }
      }
      .accessibilityHidden(true)
    }

    /// shading is what a shape of the drawing is filled with: a colour, or a linear gradient over
    /// the drawing's own units. The drawing names no token, which would read the table's light
    /// value here.
    static func shading(_ paint: GlyphDrawing.Paint) -> GraphicsContext.Shading {
      switch paint {
      case .color(let color):
        return .color(hexColor(color))
      case .token(let path, let opacity):
        var value = ElementTokens.standard[keyPath: path].light
        value.opacity *= opacity
        return .color(hexColor(value))
      case .linear(let gradient):
        let stops = gradient.stops.map {
          Gradient.Stop(color: hexColor($0.color), location: $0.offset)
        }
        let from =
          gradient.from.count == 2 ? CGPoint(x: gradient.from[0], y: gradient.from[1]) : .zero
        let to = gradient.to.count == 2 ? CGPoint(x: gradient.to[0], y: gradient.to[1]) : .zero
        return .linearGradient(Gradient(stops: stops), startPoint: from, endPoint: to)
      }
    }
  }
#endif
