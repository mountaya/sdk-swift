/// ControlMove is how a map control moves the camera (`map.camera.control-moves`), its raw value
/// the contract's spelling.
enum ControlMove: String, Sendable, CaseIterable {
  /// zoomIn steps the camera one zoom in.
  case zoomIn = "zoom-in"
  /// zoomOut steps the camera one zoom out.
  case zoomOut = "zoom-out"
  /// resetNorth turns the bearing and the pitch to 0.
  case resetNorth = "reset-north"
}
