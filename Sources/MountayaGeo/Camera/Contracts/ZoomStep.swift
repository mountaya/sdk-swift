/// ZoomStep is one of a map's two zoom controls, the step it takes, its raw value the contract's
/// spelling (`geo.camera.zoom-limit-reached`).
public enum ZoomStep: String, CaseIterable, Sendable {
  /// zoomIn is the control that steps the camera one zoom in.
  case zoomIn = "zoom-in"
  /// zoomOut is the control that steps the camera one zoom out.
  case zoomOut = "zoom-out"
}
