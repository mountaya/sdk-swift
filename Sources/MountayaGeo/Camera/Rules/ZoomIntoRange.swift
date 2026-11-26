/// zoomIntoRange is the zoom a camera at `zoom` moves to so that `window` paints
/// (`geo.camera.zoom-into-range`): a specification paints across its layers' window,
/// `paintZoomRange(_:)`, and outside it draws nothing and reports nothing, so a switch that turns it
/// on from too far out would read as a dead control.
///
/// A camera below the window moves up to its floor and one above it down to its ceiling, the nearer
/// edge. It answers nil where the camera stays: inside the window, its edges included, and before a
/// window with an end that is no finite number or a floor above its ceiling, which no move
/// satisfies. A zoom that is no number moves nowhere either.
public func zoomIntoRange(_ zoom: Double, window: ZoomBounds) -> Double? {
  guard window.minZoom.isFinite, window.maxZoom.isFinite, window.minZoom <= window.maxZoom else {
    return nil
  }
  if zoom < window.minZoom { return window.minZoom }
  if zoom > window.maxZoom { return window.maxZoom }
  return nil
}
