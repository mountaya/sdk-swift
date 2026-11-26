/// InertGeolocation is a geolocation turned off: it answers as a platform with no location services
/// does, `noApi`, and reads its permission as `denied`, so a map reads a seam that will never
/// locate rather than one still to be asked.
///
/// A stated absence rather than an omitted seam, because "this app does not locate its reader" is
/// a decision a map has to be able to read. It is bound to the main actor, as every geolocation is.
@MainActor
public struct InertGeolocation: Geolocation {
  /// Creates a geolocation that never locates.
  public init() {}

  /// locate answers no fix, as a platform with no location services does.
  public func locate() async -> GeolocationFix {
    .refused(.noApi)
  }

  /// permission answers `denied`.
  public func permission() async -> GeolocationPermission {
    .denied
  }
}
