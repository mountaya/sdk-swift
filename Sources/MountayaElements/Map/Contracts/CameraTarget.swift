import MountayaGeo

/// CameraTarget is where a camera move takes the camera: the members it states, each nil to keep
/// the camera's own (`map.camera.pose`).
///
/// `center` is `[longitude, latitude]` in degrees, two finite numbers with the latitude from -90 to
/// 90, a longitude past the antimeridian passed on as written, since a renderer reads a longitude a
/// turn away as the same meridian; `zoom`, `bearing` and `pitch` are finite numbers. A move is
/// refused before anything moves where a member it states is not one, `MapEngine.jump(to:)`,
/// `ease(to:)` and `fly(to:)` alike. A renderer holds the camera within its zoom window and the
/// latitudes it draws as it moves there.
///
/// Two are equal where they state the same members, each number as the same number, as every Geo
/// value compares.
public struct CameraTarget: Sendable, Equatable {
  /// center is the position the camera moves to, or nil to keep its own.
  public var center: [Double]?
  /// zoom is the zoom the camera moves to, or nil to keep its own.
  public var zoom: Double?
  /// bearing is the compass heading the top of the frame turns to, in degrees, or nil to keep it.
  public var bearing: Double?
  /// pitch is the tilt the camera turns to, in degrees from looking straight down, or nil to keep
  /// it.
  public var pitch: Double?

  /// Creates a move stating the members given, every other kept where the camera has it.
  public init(
    center: [Double]? = nil, zoom: Double? = nil, bearing: Double? = nil, pitch: Double? = nil
  ) {
    self.center = center
    self.zoom = zoom
    self.bearing = bearing
    self.pitch = pitch
  }

  /// Two targets are equal where they state the same members, each the same number.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameCenter(lhs.center, rhs.center) && sameMember(lhs.zoom, rhs.zoom)
      && sameMember(lhs.bearing, rhs.bearing) && sameMember(lhs.pitch, rhs.pitch)
  }

  /// applied is `camera` with every member this target states in place of its own.
  func applied(to camera: CameraPose) -> CameraPose {
    CameraPose(
      center: center ?? camera.center, zoom: zoom ?? camera.zoom, pitch: pitch ?? camera.pitch,
      bearing: bearing ?? camera.bearing)
  }

  private static func sameCenter(_ a: [Double]?, _ b: [Double]?) -> Bool {
    switch (a, b) {
    case (nil, nil): true
    case (let a?, let b?): sameNumbers(a, b)
    default: false
    }
  }

  private static func sameMember(_ a: Double?, _ b: Double?) -> Bool {
    switch (a, b) {
    case (nil, nil): true
    case (let a?, let b?): sameNumber(a, b)
    default: false
    }
  }
}
