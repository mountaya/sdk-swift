#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  internal import SwiftUI

  /// MapChrome is what a map draws over its canvas, in order from the bottom: the Mountaya
  /// watermark, clipped to the map (`geo.organization.watermark`), the label of the marker tapped
  /// last, and the readout a long press opens (`map.readout.open`). The watermark so stands above
  /// the canvas, its layers and its markers, and beneath its popups, the label and the readout
  /// among them; the panels an app's `MapControls` open are laid over the whole map, above all three.
  /// Each popup keeps to the map's safe area and clear of the watermark's frame, so none is ever
  /// drawn over the mark (`sdk/SPEC.md` §15), each is clipped to the map, whose edge cuts one no
  /// place inside the safe area clears the frame for, and each is placed by the map's points, read
  /// from its left edge in a layout that runs right to left too, the mark standing top left.
  ///
  /// It tells the engine where the map is laid out, in global coordinates, which a control stack
  /// reads the map's safe area and the watermark's frame through, to keep clear of it wherever the
  /// stack is laid (`sdk/SPEC.md` §15), each time that changes: the map laid out again, or moved in
  /// its window with no layout of its own, by a scroll view's scroll, a sheet's detent, an offset or
  /// a transform, which the engine hands its renderer so the map's safe area is measured again
  /// (`MapSurface.mapMoved()`).
  struct MapChrome: View {
    let engine: MapEngine
    let callout: MarkerCallout

    var body: some View {
      ZStack(alignment: .topLeading) {
        WatermarkLink(engine: engine)
        MarkerLabel(engine: engine, callout: callout)
        ReadoutCard(engine: engine)
      }
      .onGeometryChange(for: CGRect.self) { proxy in
        proxy.frame(in: .global)
      } action: { frame in
        engine.shown(at: MeasuredMapView.screenRect(frame))
      }
    }
  }
#endif
