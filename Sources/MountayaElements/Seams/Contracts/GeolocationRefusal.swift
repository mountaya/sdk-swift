/// GeolocationRefusal is why a geolocation answered no fix, its raw value the contract's spelling
/// (`map.camera.locate`).
public enum GeolocationRefusal: String, Sendable, Hashable, CaseIterable {
  /// denied is a fix the app holds no permission to read: one never asked for, one the reader
  /// refused, or one the reader allows only approximately, which a map reads nothing of.
  case denied
  /// noApi is a platform with no location services to ask.
  case noApi = "no_api"
  /// unavailable is location services that answered no fix in time.
  case unavailable
}
