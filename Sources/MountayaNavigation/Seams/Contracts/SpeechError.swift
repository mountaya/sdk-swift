/// SpeechError is a failure of the platform's speech, which `SpeechNavigationVoice` tells its
/// `onError`, and drops where it was given none: the speech engine did not start, so the voice says
/// nothing, or the platform refused the audio a sentence is said in.
///
/// A caller reads `kind`, one set in every SDK, `sdk-dart`'s `SpeechFailure` and `sdk-kotlin`'s
/// `SpeechException.Kind`, and `cause`, what the platform threw; `description` is written for
/// a developer reading a log, and ends on what to do.
public struct SpeechError: Error, Sendable, CustomStringConvertible {
  /// Kind is which failure a `SpeechError` is, by the name every SDK gives it.
  ///
  /// The set is open, a value over the failure's name rather than an enumeration: a later build
  /// tells a kind this one does not name, so a `switch` over it ends in `default`. Two are equal
  /// where their names are written with the same scalars.
  public struct Kind: RawRepresentable, Sendable, Hashable, CustomStringConvertible {
    /// engineUnavailable is a speech engine that did not start, so nothing will be said by the
    /// voice, told once a voice. The system's speech synthesizer always starts, so no Apple
    /// platform raises it; an Android voice does, in `sdk-kotlin` and `sdk-dart`.
    public static let engineUnavailable = Kind(rawValue: "engineUnavailable")
    /// audioRefused is the platform refusing the audio a sentence is said in, told once a refusal:
    /// the sentence is said all the same, over other apps' audio where the platform allows it. The
    /// system refuses the audio session to an app in the background that declares no `audio`
    /// mode under `UIBackgroundModes`, which is how a navigation goes silent with the screen off.
    public static let audioRefused = Kind(rawValue: "audioRefused")

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
  /// cause is what the platform threw, the audio session's error for an `audioRefused`, and
  /// nil where it threw nothing.
  public let cause: (any Error)?

  /// Creates a failure of `kind`, carrying what the platform threw, `cause`, where it threw
  /// anything.
  public init(kind: Kind, cause: (any Error)? = nil) {
    self.kind = kind
    self.cause = cause
  }

  /// description says what failed and what to do, for a developer reading a log.
  public var description: String {
    switch kind {
    case Kind.engineUnavailable:
      "The platform's speech engine did not start, so nothing is said; enable a voice in the "
        + "system's settings, or speak through a NavigationVoice of the app's own."
    case Kind.audioRefused:
      "The platform refused the audio a sentence is said in"
        + (cause.map { " (\($0))" } ?? "")
        + ", and it was said anyway; an app that speaks with the screen off declares the `audio` "
        + "mode under UIBackgroundModes in its Info.plist."
    default:
      "The platform's speech failed (\(kind))" + (cause.map { ": \($0)" } ?? "") + "."
    }
  }
}
