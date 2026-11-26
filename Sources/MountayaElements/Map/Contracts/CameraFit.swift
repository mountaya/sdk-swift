import MountayaGeo

/// CameraFit is how a camera frames a box (`map.camera.fit-options`): the inset kept clear between
/// the box and each edge of the canvas, the zoom it lands at at most, and how long it eases there,
/// each nil for the default.
///
/// `CameraFit()`, stating nothing, frames with no padding under the zoom window's ceiling, at the
/// renderer's own pace, and a fit stating members frames with those and no other. A padding or a
/// duration that is not a finite number from 0 up, and a ceiling that is not a finite number, are
/// refused before anything is read or drawn. Where the fit lands is `cameraForBounds`'s
/// (`geo.camera.fit`), which this SDK computes rather than asking its renderer.
///
/// Two are equal where they state the same, each number as the same number.
public struct CameraFit: Sendable, Equatable {
  /// padding is the inset kept clear between the box and each edge of the canvas, in points, or
  /// nil for none.
  public var padding: PixelPadding?
  /// maxZoom is the highest zoom the fit lands at, or nil for the zoom window's ceiling. A ceiling
  /// past the window is handed on, and the window holds the camera under its own.
  public var maxZoom: Double?
  /// duration is how long the camera eases to the fit, or nil for the renderer's own pace.
  public var duration: Duration?

  /// Creates a fit stating the members given, each other left to its default.
  public init(padding: PixelPadding? = nil, maxZoom: Double? = nil, duration: Duration? = nil) {
    self.padding = padding
    self.maxZoom = maxZoom
    self.duration = duration
  }

  /// Two fits are equal where they state the same members, each the same number.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.padding == rhs.padding && lhs.duration == rhs.duration
      && sameCeiling(lhs.maxZoom, rhs.maxZoom)
  }

  private static func sameCeiling(_ a: Double?, _ b: Double?) -> Bool {
    switch (a, b) {
    case (nil, nil): true
    case (let a?, let b?): sameNumber(a, b)
    default: false
    }
  }
}
