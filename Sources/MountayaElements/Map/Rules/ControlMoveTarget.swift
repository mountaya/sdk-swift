import MountayaGeo

/// controlMoveTarget is where a map control moves `camera` (`map.camera.control-moves`): a zoom
/// step one zoom level in or out from the zoom it stands at, unrounded and held within `window`, so
/// a step past an end stops at it; a reset of north the bearing and the pitch turned to 0. Each
/// keeps every other member of the camera, which a renderer's own verb may not, one rounding the
/// zoom or keeping the pitch.
func controlMoveTarget(_ camera: CameraPose, window: ZoomBounds, move: ControlMove) -> CameraPose {
  var target = camera
  switch move {
  case .zoomIn:
    target.zoom = held(camera.zoom + 1, within: window)
  case .zoomOut:
    target.zoom = held(camera.zoom - 1, within: window)
  case .resetNorth:
    target.bearing = 0
    target.pitch = 0
  }
  return target
}

/// held is `zoom` brought within `window`, a zoom that is no number left as it is.
private func held(_ zoom: Double, within window: ZoomBounds) -> Double {
  if zoom > window.maxZoom { return window.maxZoom }
  if zoom < window.minZoom { return window.minZoom }
  return zoom
}
