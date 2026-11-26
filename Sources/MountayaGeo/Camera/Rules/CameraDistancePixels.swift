/// defaultViewportHeightPixels is the canvas height, in screen pixels, a camera's altitude and
/// zoom are converted at where the caller names none, the `defaultViewportHeightPx`
/// `geo/zoom-altitude.json` declares: a nominal canvas, so a conversion needs no live map.
let defaultViewportHeightPixels: Double = 800

/// fieldOfViewDistanceFactor is the camera's distance from the screen in canvas heights,
/// `1 / (2 × tan(fov / 2))` for a vertical field of view of about 36.87 degrees, the renderer's
/// default: the `fieldOfViewFactor` `geo/zoom-altitude.json` declares.
let fieldOfViewDistanceFactor: Double = 1.5

/// cameraDistancePixels is the camera's distance from the screen, in screen pixels, for a canvas
/// of a height: the height the perspective model scales an altitude to ground by. A height that is
/// not a finite number above zero is no canvas, and the nominal one is read instead.
func cameraDistancePixels(_ viewportHeightPixels: Double) -> Double {
  let height =
    viewportHeightPixels.isFinite && viewportHeightPixels > 0
    ? viewportHeightPixels : defaultViewportHeightPixels
  return height * fieldOfViewDistanceFactor
}
