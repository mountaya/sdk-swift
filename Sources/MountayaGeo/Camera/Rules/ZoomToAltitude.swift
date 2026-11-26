/// safeMidAltitudeMeters is the altitude a zoom that converts to none answers, the safe mid
/// altitude `geo/zoom-altitude.json` states.
let safeMidAltitudeMeters: Double = 1_000

/// zoomToAltitude is the altitude in meters, above the ground it looks at, at which a camera at a
/// latitude in degrees shows that ground at a Web Mercator zoom, on a canvas
/// `viewportHeightPixels` tall: the ground resolution, `groundMetersPerPixel` at the zoom and the
/// latitude, across the camera's distance from the screen, one and a half canvas heights.
///
/// It is the inverse of `altitudeToZoom(_:latitude:viewportHeightPixels:)`, and holds the altitude
/// to no range, since a clearance pass reads eye heights against terrain in meters. A zoom that is
/// no finite number, or a conversion that yields no altitude above zero (a latitude that is `NaN`
/// or past a pole, or a zoom so far out the altitude overflows), answers the safe mid altitude,
/// 1,000 m. A height that is not a finite number above zero is no canvas, and the nominal
/// 800-pixel one is read instead.
public func zoomToAltitude(
  _ zoom: Double, latitude: Double, viewportHeightPixels: Double = 800
) -> Double {
  guard zoom.isFinite else { return safeMidAltitudeMeters }
  let altitude =
    groundMetersPerPixel(zoom: zoom, latitude: latitude)
    * cameraDistancePixels(viewportHeightPixels)
  return altitude.isFinite && altitude > 0 ? altitude : safeMidAltitudeMeters
}
