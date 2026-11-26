#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import MountayaGeo
  internal import SwiftUI

  /// MarkerLabel is the label of the marker tapped last, `callout`'s, beside its pin as the camera
  /// stands: 18 points past the marker's point toward the end its text runs to, centred on it, held
  /// inside the map's safe area and moved clear of the watermark's frame by the smallest move, the
  /// frame held clear while the read of the organization waits too, as a readout is
  /// (`markerLabelPlacement`, `sdk/SPEC.md` §15), on the tooltip's ground in the tokens of its
  /// environment under the scheme in force, and clipped to the map. It draws nothing where the
  /// marker has no label, the map holds it no more or its point is off the canvas, whose label is
  /// never held at the map's edge without its pin (`isMarkerLabelShown`), and takes no touch, so
  /// the map under it keeps every gesture.
  ///
  /// It stands where a map's popups do, above the watermark and under the readout, which a map's own
  /// callout, drawn inside MapLibre's view, could not, and never over the mark. It reads the
  /// callout's moves, so it follows its marker while the camera moves, and SwiftUI draws it for
  /// nothing else.
  struct MarkerLabel: View {
    let engine: MapEngine
    let callout: MarkerCallout

    @Environment(\.sharedTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.layoutDirection) private var direction

    var body: some View {
      // The moves are read so the label is drawn again where the camera moved it.
      let labelled = labelled(callout.moves)
      let isRightToLeft = direction == .rightToLeft
      let safeArea = engine.safeArea
      let frame =
        isWatermarkKeptClear(engine.organizationRead) ? watermarkFrame(safeArea: safeArea) : nil
      GeometryReader { proxy in
        let placed = Self.placed(labelled, canvas: proxy.size)
        let bounds = safeAreaBounds(
          safeArea, width: Double(proxy.size.width), height: Double(proxy.size.height))
        // Where the label stands once drawn as large as it is.
        let rect: @Sendable (ViewDimensions) -> ScreenRect? = { drawn in
          markerLabelPlacement(
            at: placed?.point ?? [], width: Double(drawn.width), height: Double(drawn.height),
            isRightToLeft: isRightToLeft, within: bounds, clearOf: frame)
        }
        // The label is always laid out, and hidden where none is shown: an overlay reads no
        // alignment guide off a view it holds conditionally.
        Color.clear
          .overlay(alignment: .topLeading) {
            label(placed?.text ?? "")
              .alignmentGuide(HorizontalAlignment.leading) { drawn in
                -(rect(drawn)?.x ?? 0)
              }
              .alignmentGuide(VerticalAlignment.top) { drawn in
                -(rect(drawn)?.y ?? 0)
              }
              .opacity(placed == nil ? 0 : 1)
              .accessibilityHidden(placed == nil)
          }
      }
      .clipped()
      // The canvas's points run from its left edge whatever the reader's direction.
      .environment(\.layoutDirection, .leftToRight)
      .allowsHitTesting(false)
    }

    /// labelled is the label of the marker tapped last and the point of its marker as the camera
    /// stands, or nil where no marker the map holds is labelled; `moves` is the count of moves it
    /// is read at.
    private func labelled(_ moves: Int) -> (text: String, point: [Double])? {
      guard let id = callout.markerId,
        let marker = engine.state.markers.last(where: { sameText($0.id, id) }),
        let text = marker.label
      else { return nil }
      return (text, engine.project(marker.position))
    }

    /// placed is `labelled`, a label and the point of its marker, where it is drawn on a canvas of
    /// `canvas`'s size, or nil where none is: where no marker is labelled, or its point names no
    /// place or stands off the canvas, so a label is never held at the map's edge without its pin
    /// (`isMarkerLabelShown`, `sdk/SPEC.md` §15).
    static func placed(_ labelled: (text: String, point: [Double])?, canvas: CGSize) -> (
      text: String, point: [Double]
    )? {
      guard let labelled,
        isMarkerLabelShown(
          at: labelled.point, mapWidth: Double(canvas.width), mapHeight: Double(canvas.height))
      else { return nil }
      return labelled
    }

    /// label is `text` on the tooltip's ground, its text in the reader's direction.
    private func label(_ text: String) -> some View {
      let scheme = themeScheme(colorScheme)
      return Text(verbatim: text)
        .font(.footnote)
        .environment(\.layoutDirection, direction)
        .foregroundStyle(tokenColor(tokens.value.tooltipFg, in: scheme))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
          tokenColor(tokens.value.tooltipBg, in: scheme), in: RoundedRectangle(cornerRadius: 4)
        )
        .fixedSize()
    }
  }
#endif
