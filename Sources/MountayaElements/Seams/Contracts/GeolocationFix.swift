import MountayaGeo

/// GeolocationFix is what asking for the device's position answered: where it stands and how
/// precisely, or the reason there is no fix.
///
/// The accuracy travels with the position because framing a camera on a fix needs both: a coarse
/// fix that filled the view at street zoom would claim a precision it does not have. Two are equal
/// where they hold the same, each number as the same number.
public enum GeolocationFix: Sendable, Equatable {
  /// located is a fix: `position` is `[longitude, latitude]`, and `accuracyMeters` how far from it
  /// the device may stand.
  case located(position: [Double], accuracyMeters: Double)
  /// refused is no fix, for the reason named.
  case refused(GeolocationRefusal)

  /// Two fixes are equal where they are of one kind and hold the same.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.located(let a, let aAccuracy), .located(let b, let bAccuracy)):
      sameNumbers(a, b) && sameNumber(aAccuracy, bAccuracy)
    case (.refused(let a), .refused(let b)):
      a == b
    default:
      false
    }
  }
}
