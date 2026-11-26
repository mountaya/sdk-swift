/// zoomLimitReached is which end of its zoom window a camera at `zoom` stands at
/// (`geo.camera.zoom-limit-reached`): the ceiling at it or above it, the floor at it or below it,
/// both in a window of one zoom, and none otherwise. The zoom is read unrounded, so a camera a
/// fraction under the ceiling stands at no end; a renderer holds its camera within the window, and
/// a camera found past an end stands at that end. A zoom that is no number stands at none.
public func zoomLimitReached(_ zoom: Double, window: ZoomBounds) -> ZoomWindowEnd {
  let atCeiling = zoom >= window.maxZoom
  let atFloor = zoom <= window.minZoom
  switch (atFloor, atCeiling) {
  case (true, true): return .both
  case (false, true): return .ceiling
  case (true, false): return .floor
  case (false, false): return ZoomWindowEnd.none
  }
}

/// zoomControlsDisabled is the zoom controls disabled where a camera stands at `end` of its window:
/// zoom in at the ceiling, zoom out at the floor, both in a window of one zoom and none inside it.
/// A control is disabled there whoever answers its press, the map or a handler of the host's that
/// takes the press over, since either would move the camera nowhere. `ZoomControl` reads it.
public func zoomControlsDisabled(at end: ZoomWindowEnd) -> [ZoomStep] {
  switch end {
  case ZoomWindowEnd.none: []
  case .floor: [.zoomOut]
  case .ceiling: [.zoomIn]
  case .both: [.zoomIn, .zoomOut]
  }
}
