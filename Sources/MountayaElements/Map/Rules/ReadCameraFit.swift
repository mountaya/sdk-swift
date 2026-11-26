import MountayaGeo

/// readCameraFit reads a fit's options before anything is read or drawn
/// (`map.camera.fit-options`): it answers the fit as stated, a member left nil taking its default.
///
/// It throws a `MapError` of kind `numberRefused` where the ceiling is not a finite number, where
/// the duration is under 0, or where any edge of the padding is not a finite number from 0 up, the
/// ceiling read first, then the duration and the padding; the error names the member refused. A
/// duration that is no finite number cannot be written, since a `Duration` holds none.
func readCameraFit(_ fit: CameraFit) throws(MapError) -> CameraFit {
  if let maxZoom = fit.maxZoom, !maxZoom.isFinite {
    throw MapError(kind: .numberRefused, name: "maxZoom")
  }
  if let duration = fit.duration, duration < .zero {
    throw MapError(kind: .numberRefused, name: "duration")
  }
  if let padding = fit.padding {
    let edges = [padding.top, padding.right, padding.bottom, padding.left]
    guard edges.allSatisfy({ $0.isFinite && $0 >= 0 }) else {
      throw MapError(kind: .numberRefused, name: "padding")
    }
  }
  return fit
}
