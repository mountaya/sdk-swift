/// LocationError is a failure of the device's location reader, which `DeviceLocationSource` tells
/// its `onError`, and drops where it was given none: the device holds no location provider, its
/// location services are switched off, the app's access went while it read, the location services
/// failed on their own, or the app asked to read with the screen off and its Info.plist declares
/// no mode for it. The source keeps reading where it can, and fixes resume once the platform hands
/// them again.
///
/// A caller reads `kind`, one set in every SDK, `sdk-dart`'s `LocationFailure` and `sdk-kotlin`'s
/// `LocationException.Kind`, and `cause`, what the platform reported; `description` is written
/// for a developer reading a log, and ends on what to do.
///
/// ```swift
/// let source = DeviceLocationSource(onError: { error in
///   if (error as? LocationError)?.kind == .providerDisabled {
///     showLocationOffBanner()
///   }
/// })
/// ```
public struct LocationError: Error, Sendable, CustomStringConvertible {
  /// Kind is which failure a `LocationError` is, by the name every SDK gives it.
  ///
  /// The set is open, a value over the failure's name rather than an enumeration: a later build
  /// tells a kind this one does not name, so a `switch` over it ends in `default`. Two are equal
  /// where their names are written with the same scalars.
  public struct Kind: RawRepresentable, Sendable, Hashable, CustomStringConvertible {
    /// noProvider is a device that holds no location provider at all. The location services of
    /// an Apple platform always hold one, so none raises it; an Android reader does, in
    /// `sdk-kotlin` and `sdk-dart`.
    public static let noProvider = Kind(rawValue: "noProvider")
    /// providerDisabled is the device's location services switched off, for every app: found as
    /// the source starts, or as the services refuse it access while they are off. No fix comes
    /// until the traveller turns them on again.
    public static let providerDisabled = Kind(rawValue: "providerDisabled")
    /// permissionRevoked is the app's access to the device's location withdrawn while the source
    /// reads, which shows in its `standing` too: nothing is read until it is granted again.
    public static let permissionRevoked = Kind(rawValue: "permissionRevoked")
    /// platformFailed is any other failure the location services report, carried as
    /// `cause`. The source reads on.
    public static let platformFailed = Kind(rawValue: "platformFailed")
    /// backgroundUndeclared is `backgroundUpdates` asked where the app declares no `location`
    /// mode under `UIBackgroundModes` in its Info.plist, or on visionOS, which reads no location in
    /// the background: refused, since turning the updates on without the mode ends the app, and
    /// the positions read while the app is in use.
    public static let backgroundUndeclared = Kind(rawValue: "backgroundUndeclared")
    /// audioUndeclared is `backgroundUpdates` asked where the app declares no `audio` mode under
    /// `UIBackgroundModes`, on an iPhone or an iPad, where the system refuses a voice the audio
    /// session in the background: a prompt is not heard with the screen off. The source reads on
    /// in the background.
    public static let audioUndeclared = Kind(rawValue: "audioUndeclared")

    /// rawValue is the kind's name, as every SDK and a log write it.
    public let rawValue: String

    /// Creates the kind `rawValue` names.
    public init(rawValue: String) {
      self.rawValue = rawValue
    }

    /// description is the kind's name.
    public var description: String {
      rawValue
    }

    /// Two kinds are the same where their names are written with the same scalars.
    public static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.rawValue.unicodeScalars.elementsEqual(rhs.rawValue.unicodeScalars)
    }

    /// hash feeds the name's scalars.
    public func hash(into hasher: inout Hasher) {
      for scalar in rawValue.unicodeScalars {
        hasher.combine(scalar)
      }
    }
  }

  /// kind is which failure it is.
  public let kind: Kind
  /// cause is what the platform reported, the location services' error for a
  /// `permissionRevoked`, a `platformFailed` or a `providerDisabled` they refused access for, and
  /// nil where the source found the failure itself.
  public let cause: (any Error)?

  /// Creates a failure of `kind`, carrying what the platform reported, `cause`, where it
  /// reported anything.
  public init(kind: Kind, cause: (any Error)? = nil) {
    self.kind = kind
    self.cause = cause
  }

  /// description says what failed and what to do, for a developer reading a log.
  public var description: String {
    switch kind {
    case Kind.noProvider:
      "The device holds no location provider to read; navigate with the app's own positions, a "
        + "StreamLocationSource, or a ReplayLocationSource."
    case Kind.providerDisabled:
      "The device's location services are switched off; fixes resume once the traveller turns "
        + "them on in the system's settings."
    case Kind.permissionRevoked:
      "Location access was withdrawn as the source read; ask for it again in the app's own flow, "
        + "at full accuracy, then call DeviceLocationSource.recheckPermission()."
    case Kind.platformFailed:
      "The device's location services reported a failure"
        + (cause.map { " (\($0))" } ?? "") + "; the source keeps reading."
    case Kind.backgroundUndeclared:
      "Background location updates were refused: the app declares no `location` mode under "
        + "UIBackgroundModes in its Info.plist, or runs on a platform that reads no location in "
        + "the background. Positions are still read while the app is in use."
    case Kind.audioUndeclared:
      "The app reads its location in the background but declares no `audio` mode under "
        + "UIBackgroundModes in its Info.plist, so a voice is silent while the screen is off. "
        + "Positions are still read, and prompts are said while the app is in use."
    default:
      "The device's location reader failed (\(kind))"
        + (cause.map { ": \($0)" } ?? "") + "."
    }
  }
}
