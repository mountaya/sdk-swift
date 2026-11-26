/// LocationStanding is where the app stands on location access: whether it may read the device's
/// location, and how precisely.
///
/// `DeviceLocationSource` reads positions only where `authorization` is `whenInUse` or `always`
/// and `accuracy` is `full`. Two are equal where both members are.
public struct LocationStanding: Sendable, Hashable {
  /// authorization is whether the app may read the device's location.
  public var authorization: LocationAuthorization
  /// accuracy is how precisely it may read it.
  public var accuracy: LocationAccuracy

  /// Creates a standing of `authorization` at `accuracy`.
  public init(authorization: LocationAuthorization, accuracy: LocationAccuracy) {
    self.authorization = authorization
    self.accuracy = accuracy
  }

  /// isReadable tells whether a navigation reads positions under this standing: access granted,
  /// while the app is in use or always, at full accuracy.
  var isReadable: Bool {
    switch authorization {
    case .whenInUse, .always: accuracy == .full
    case .notDetermined, .restricted, .denied: false
    }
  }
}
