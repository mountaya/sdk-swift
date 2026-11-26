/// CameraMotion is how a renderer moves the camera to a target: at once, along a straight ease, or
/// along the curved flight that pulls out and back in. Where the camera lands is the contract's;
/// how it travels there, and for how long, is the platform's.
public enum CameraMotion: Sendable, Hashable {
  /// jump moves the camera at once.
  case jump
  /// ease moves the camera along a straight ease, over `duration`, or the renderer's own duration
  /// where it is nil, as it is where none is given: `.ease()`.
  case ease(duration: Duration? = nil)
  /// fly moves the camera along a curved flight, over the renderer's own duration.
  case fly
}
