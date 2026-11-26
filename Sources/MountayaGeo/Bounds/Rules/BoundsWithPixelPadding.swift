/// boundsWithPixelPadding grows a box, `[west, south, east, north]` in degrees, outward by a
/// padding in screen pixels at a zoom and a centre latitude: the ground the box and its insets
/// cover together when the box is framed with that padding at that zoom.
///
/// A pixel spans the ground resolution of 512-pixel tiles, `groundMetersPerPixel(zoom:latitude:)`,
/// read in the degree of the same sphere: a pixel of longitude is the same span of degrees at
/// every latitude, `360 / (512 × 2^zoom)`, and a pixel of latitude that span times the cosine of
/// the centre latitude, which is held within `webMercatorMaxLatitude` so the resolution stays
/// positive. The edges move as written, so an east edge past 180 grows past it, a padding under
/// zero insets the box, and nothing is reordered or wrapped. It is a local linear reading, close
/// at the zooms a route is framed at.
///
/// A zoom that is no finite number spans no ground per pixel, so the box comes back as it is
/// written. Nothing is refused: a centre latitude that is `NaN` answers `NaN` latitudes, and a box
/// that is not four numbers answers four `NaN`s.
public func boundsWithPixelPadding(
  _ bounds: [Double], padding: PixelPadding, zoom: Double, centerLatitude: Double
) -> [Double] {
  guard bounds.count == 4 else { return [.nan, .nan, .nan, .nan] }
  let latitude = clampNumber(
    centerLatitude, to: -webMercatorMaxLatitude...webMercatorMaxLatitude)
  let degreesLongitudePerPixel =
    groundMetersPerPixel(zoom: zoom, latitude: 0) / metersPerDegreeWebMercator
  let degreesLatitudePerPixel =
    groundMetersPerPixel(zoom: zoom, latitude: latitude) / metersPerDegreeWebMercator
  return [
    bounds[0] - padding.left * degreesLongitudePerPixel,
    bounds[1] - padding.bottom * degreesLatitudePerPixel,
    bounds[2] + padding.right * degreesLongitudePerPixel,
    bounds[3] + padding.top * degreesLatitudePerPixel,
  ]
}
