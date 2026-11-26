import Foundation

/// cameraForBounds is the camera that fits a box in a canvas (`geo.camera.fit`), computed rather
/// than asked of a renderer, since a renderer's own fit takes no zoom ceiling and may keep the
/// bearing: the viewport it answers faces north, and a camera framing it keeps the pitch it has.
///
/// `bounds` is `[west, south, east, north]` in degrees, in the canonical form
/// `normalizeBoundingBox(_:)` writes, which a map reads any box in before it frames it: each axis
/// ordered, one across the antimeridian written with its east edge past 180, and its latitudes
/// within `webMercatorMaxLatitude`. The fit does not normalize. `canvas` is `[width, height]` in
/// screen pixels, `padding` the inset kept clear between the box and each edge of the canvas,
/// `maxZoom` the fit's ceiling, the window's where it is nil, and `window` the zoom window the
/// camera is held to.
///
/// The box is projected on the Web Mercator world, one tile of `webMercatorTileSizePixels` at zoom
/// 0, and the zoom is the highest at which that projection fits the canvas less its padding: the
/// base-2 logarithm of the lesser of the room across over the box's projected width and the room
/// down over its projected height, each over the tile size. It is held under the fit's ceiling,
/// then within the window. The centre is the box's projected middle moved by half the difference
/// of opposite paddings, `(left - right) / 2` pixels west and `(top - bottom) / 2` pixels north at
/// the zoom the camera lands at, then unprojected; a box of one point fits at every zoom and is
/// framed at the ceiling. A box across the antimeridian is centred past 180 where its middle is,
/// which a renderer reads as the same meridian.
///
/// The answer is nil where the padding leaves the canvas no room, a canvas or a padding that is no
/// number included, and where the box is not four numbers or the canvas not two. An edge of the box
/// that is `NaN` is kept unknown: it answers a viewport holding `NaN` rather than a guess.
public func cameraForBounds(
  _ bounds: [Double], canvas: [Double], padding: PixelPadding = PixelPadding(0),
  maxZoom: Double? = nil, window: ZoomBounds
) -> MapViewport? {
  guard bounds.count == 4, canvas.count == 2 else { return nil }
  let roomX = canvas[0] - padding.left - padding.right
  let roomY = canvas[1] - padding.top - padding.bottom
  guard roomX > 0, roomY > 0 else { return nil }

  // The box on the world square, which is one tile at zoom 0, from 0 at its west and north edges
  // to 1 at its east and south ones.
  let x0 = worldX(bounds[0])
  let x1 = worldX(bounds[2])
  let y0 = worldY(bounds[3])
  let y1 = worldY(bounds[1])
  let fits = log2(
    minimumNumber(roomX / (x1 - x0), roomY / (y1 - y0)) / webMercatorTileSizePixels)
  let ceiling = minimumNumber(maxZoom ?? window.maxZoom, window.maxZoom)
  let zoom = maximumNumber(minimumNumber(fits, ceiling), window.minZoom)

  // The inset an uneven padding leaves on one side moves the middle by half the difference, in
  // pixels at the zoom the camera lands at.
  let worldPixels = webMercatorTileSizePixels * pow(2, zoom)
  let x = (x0 + x1) / 2 - (padding.left - padding.right) / 2 / worldPixels
  let y = (y0 + y1) / 2 - (padding.top - padding.bottom) / 2 / worldPixels
  return MapViewport(center: [(x - 0.5) * degreesPerTurn, latitudeAt(y)], zoom: zoom)
}

/// worldX is a longitude's place across the Web Mercator world, from 0 at -180 to 1 at 180, past
/// either where the longitude is past the antimeridian.
private func worldX(_ longitude: Double) -> Double {
  longitude / degreesPerTurn + 0.5
}

/// worldY is a latitude's place down the Web Mercator world, from 0 at its north edge to 1 at its
/// south one.
private func worldY(_ latitude: Double) -> Double {
  0.5 - atanh(sin(latitude * radiansPerDegree)) / (2 * .pi)
}

/// latitudeAt is the latitude at a place down the Web Mercator world, the inverse of `worldY(_:)`.
private func latitudeAt(_ y: Double) -> Double {
  asin(tanh(.pi * (1 - 2 * y))) * degreesPerRadian
}
