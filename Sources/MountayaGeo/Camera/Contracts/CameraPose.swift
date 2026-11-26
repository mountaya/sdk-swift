/// CameraPose is one frame of a camera: the position it is centred on, how far it is zoomed, how
/// far it is tilted from looking straight down, and the compass heading the top of the frame
/// faces.
///
/// Two poses are equal where every field holds the same numbers, `NaN` the same as `NaN` and 0
/// another than -0, as every value of the geo layer compares; no tolerance is applied. Equal
/// values hash alike.
public struct CameraPose: Sendable, Hashable {
  /// center is the position the camera is centred on, `[longitude, latitude]` in degrees, as the
  /// wire orders a position.
  public var center: [Double]
  /// zoom is the zoom level, on the scale every map of this SDK reads: 0 shows the whole world.
  public var zoom: Double
  /// pitch is the tilt from looking straight down, in degrees: 0 looks at the ground from above.
  public var pitch: Double
  /// bearing is the compass heading the top of the frame faces, in degrees: 0 north and 90 east.
  public var bearing: Double

  /// Creates a frame from its center, zoom, pitch and bearing.
  public init(center: [Double], zoom: Double, pitch: Double, bearing: Double) {
    self.center = center
    self.zoom = zoom
    self.pitch = pitch
    self.bearing = bearing
  }

  /// Two poses are equal where every field is the same number.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameNumbers(lhs.center, rhs.center) && sameNumber(lhs.zoom, rhs.zoom)
      && sameNumber(lhs.pitch, rhs.pitch) && sameNumber(lhs.bearing, rhs.bearing)
  }

  /// hash feeds every field as the same-number relation reads it.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(sameNumbers: center)
    hasher.combine(sameNumber: zoom)
    hasher.combine(sameNumber: pitch)
    hasher.combine(sameNumber: bearing)
  }
}
