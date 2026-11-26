import MountayaGeo

/// readCameraTarget reads a camera move's target before anything moves (`map.camera.pose`): it
/// answers the target as stated, each member it leaves nil kept where the camera has it, and a
/// centre past the antimeridian handed on as written, since a renderer reads a longitude a turn
/// away as the same meridian.
///
/// It throws a `MapError` of kind `positionRefused` where the centre is not two finite numbers with
/// the latitude from -90 to 90, an altitude beside them included, and of kind `numberRefused` where
/// the zoom, the bearing or the pitch is not a finite number, the centre read first, then the zoom,
/// the bearing and the pitch; the error names the member refused.
func readCameraTarget(_ target: CameraTarget) throws(MapError) -> CameraTarget {
  if let center = target.center {
    guard center.count == 2, center[0].isFinite, center[1].isFinite, abs(center[1]) <= 90 else {
      throw MapError(kind: .positionRefused, name: "center")
    }
  }
  for (member, value) in [
    ("zoom", target.zoom), ("bearing", target.bearing), ("pitch", target.pitch),
  ] {
    if let value, !value.isFinite {
      throw MapError(kind: .numberRefused, name: member)
    }
  }
  return target
}
