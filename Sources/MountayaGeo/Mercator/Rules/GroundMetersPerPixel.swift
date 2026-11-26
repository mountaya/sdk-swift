import Foundation

/// webMercatorCircumferenceMeters is the circumference of the Web Mercator sphere at the equator,
/// the `webMercatorCircumferenceMeters` `geo/pixel-padding.json` declares: the sphere a renderer
/// resolves pixels on, which is not the mean sphere a distance on the ground is measured on.
public let webMercatorCircumferenceMeters: Double = 40_075_016.686

/// webMercatorTileSizePixels is the side of one tile of the renderer's world, in screen pixels,
/// the `tileSizePx` `geo/pixel-padding.json` declares: at zoom 0 the whole world is one tile this
/// wide.
public let webMercatorTileSizePixels: Double = 512

/// webMercatorMaxLatitude is the latitude, north and south, past which Web Mercator draws
/// nothing, the `webMercatorMaxLatitude` `geo/pixel-padding.json` and
/// `geo/normalize-bounding-box.json` declare: a box is held within it, and so is a latitude a
/// pixel is resolved at where the resolution must stay positive.
public let webMercatorMaxLatitude: Double = 85.051129

/// metersPerDegreeWebMercator is the ground length of one degree of arc on the Web Mercator
/// sphere, its circumference over a turn: a degree of latitude anywhere and a degree of longitude
/// at the equator, on the sphere a pixel is resolved on.
let metersPerDegreeWebMercator: Double = webMercatorCircumferenceMeters / degreesPerTurn

/// groundMetersPerPixel is the Web Mercator ground resolution at a zoom and a latitude, in
/// degrees: the meters of ground one screen pixel spans,
/// `40075016.686 × cos(latitude) / (512 × 2^zoom)`. Every conversion between screen pixels and
/// ground distance in the geo layer goes through it.
///
/// A zoom that is no finite number spans no ground and answers 0. A latitude is read as written:
/// past a pole the cosine, and so the answer, is negative, and a latitude that is `NaN` answers
/// `NaN`; a caller that needs a positive resolution holds the latitude within
/// `webMercatorMaxLatitude` first.
public func groundMetersPerPixel(zoom: Double, latitude: Double) -> Double {
  guard zoom.isFinite else { return 0 }
  return webMercatorCircumferenceMeters * cos(latitude * radiansPerDegree)
    / (webMercatorTileSizePixels * pow(2, zoom))
}
