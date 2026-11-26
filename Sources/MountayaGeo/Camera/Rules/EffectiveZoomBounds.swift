/// effectiveMinZoomFloor is the least zoom a map is ever held to, the `effectiveMinZoomFloor`
/// `geo/zoom-bounds.json` declares: a range that lets the camera pull out further is floored
/// here.
let effectiveMinZoomFloor: Double = 3

/// zoomBuffer is the headroom a range's ceiling is pulled in by, for the drift pitch and terrain
/// give a camera's effective zoom, the `zoomBuffer` `geo/zoom-bounds.json` declares.
let zoomBuffer: Double = 1

/// effectiveZoomMinSpan is the least span kept between the floored minimum and the buffered
/// maximum, the `effectiveZoomMinSpan` `geo/zoom-bounds.json` declares: a renderer refuses a
/// maximum at or under its minimum.
let effectiveZoomMinSpan: Double = 1

/// effectiveZoomBounds is the zoom range a map's camera is held to for a layer, or an
/// organization's safety rules, that serves `zoomMin` to `zoomMax`: the minimum floored at an
/// absolute 3, and the maximum pulled in by a buffer of 1 for the drift pitch and terrain give,
/// never closer to the minimum than a span of 1. The minimum, the end that bounds how far a camera
/// may pull out, keeps its value; it is the maximum that widens a narrow range.
///
/// The wire's zooms are whole numbers, and a caller passes them as `Double`, the type of every
/// zoom in the geo layer; a fraction is held as written. Nothing is refused or ordered: a minimum
/// that is `NaN` answers `NaN` at both ends, and a maximum that is `NaN` at the maximum.
public func effectiveZoomBounds(zoomMin: Double, zoomMax: Double) -> ZoomBounds {
  let minZoom = maximumNumber(zoomMin, effectiveMinZoomFloor)
  return ZoomBounds(
    minZoom: minZoom,
    maxZoom: maximumNumber(zoomMax - zoomBuffer, minZoom + effectiveZoomMinSpan)
  )
}
