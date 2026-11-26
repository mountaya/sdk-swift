/// LocationAuthorization is whether the app may read the device's location, as the platform's
/// location services state it.
///
/// A platform states what it knows: macOS grants no access that lasts only while the app is in
/// use, so an app there reads `always` once it is granted access.
public enum LocationAuthorization: Sendable, Hashable, CaseIterable {
  /// notDetermined is an app that has not asked, so the platform would prompt the reader.
  case notDetermined
  /// restricted is a policy the reader cannot change, such as parental controls, forbidding it.
  case restricted
  /// denied is the reader having refused it, or location services turned off.
  case denied
  /// whenInUse is the reader allowing it while the app is in use.
  case whenInUse
  /// always is the reader allowing it always, with the screen off included.
  case always
}
