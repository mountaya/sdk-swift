/// ZoomWindowEnd is which end of its zoom window a camera stands at (`geo.camera.zoom-limit-reached`):
/// none, its floor, its ceiling, or both in a window of one zoom, each named and spelled as the
/// contract names it. A comparison with an optional writes `ZoomWindowEnd.none` in full, since
/// `.none` there reads as `Optional.none`.
public enum ZoomWindowEnd: String, CaseIterable, Sendable {
  /// none is a camera inside its window, a fraction from either end included.
  case none
  /// floor is a camera at its window's floor or below it.
  case floor
  /// ceiling is a camera at its window's ceiling or above it.
  case ceiling
  /// both is a camera in a window of one zoom, at its floor and its ceiling at once.
  case both
}
