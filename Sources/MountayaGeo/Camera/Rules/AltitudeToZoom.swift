import Foundation

/// safeMidZoom is the zoom an altitude that converts to none answers, the safe mid zoom
/// `geo/zoom-altitude.json` states.
let safeMidZoom: Double = 12

/// altitudeZoomCeiling is the greatest zoom an altitude converts to, the `zoomCeiling`
/// `geo/zoom-altitude.json` declares (400 m at 45.9 degrees is zoom 16).
let altitudeZoomCeiling: Double = 16

/// altitudeZoomFloor is the least zoom an altitude converts to, the `zoomFloor`
/// `geo/zoom-altitude.json` declares (12,000,000 m at 45.9 degrees is zoom 4).
let altitudeZoomFloor: Double = 4

/// altitudeToZoom is the Web Mercator zoom at which a camera an altitude in meters above the
/// ground it looks at, at a latitude in degrees, shows that ground, on a canvas
/// `viewportHeightPixels` tall: the zoom whose ground resolution, `groundMetersPerPixel` at the
/// latitude, spans the altitude across the camera's distance from the screen, one and a half
/// canvas heights. So the same altitude is a different zoom at the equator and at sixty degrees.
///
/// The answer is held within [4, 16], the zooms a flight is framed at. An altitude that is no
/// finite number above zero, or a conversion that yields no finite zoom (a latitude that is `NaN`
/// or past a pole), answers the safe mid zoom, 12. A height that is not a finite number above zero
/// is no canvas, and the nominal 800-pixel one is read instead. The inverse is
/// `zoomToAltitude(_:latitude:viewportHeightPixels:)`.
public func altitudeToZoom(
  _ altitudeMeters: Double, latitude: Double, viewportHeightPixels: Double = 800
) -> Double {
  guard altitudeMeters.isFinite, altitudeMeters > 0 else { return safeMidZoom }
  // The zoom at which one pixel spans the altitude over the camera's distance from the screen:
  // 2^zoom is the resolution at zoom 0 over that span.
  let zoom = log2(
    groundMetersPerPixel(zoom: 0, latitude: latitude) * cameraDistancePixels(viewportHeightPixels)
      / altitudeMeters)
  guard zoom.isFinite else { return safeMidZoom }
  return clampNumber(zoom, to: altitudeZoomFloor...altitudeZoomCeiling)
}
