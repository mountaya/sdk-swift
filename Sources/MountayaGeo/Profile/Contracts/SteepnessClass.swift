/// SteepnessClass is a band of the steepness classification a slope overlay paints, the table kept
/// apart from the slope ramp with thresholds of its own. Each is spelled by its contract id and
/// starts at `fromDegrees`, the class above it starting where it ends; a slope under the first
/// class has none.
///
/// The cases are declared from the gentlest to the steepest, the order `allCases` yields and the
/// order a slope is classified in.
public enum SteepnessClass: String, CaseIterable, Sendable {
  /// from25To30 is 25 degrees, up to 30.
  case from25To30 = "25-30"
  /// from30To35 is 30 degrees, up to 35.
  case from30To35 = "30-35"
  /// from35To40 is 35 degrees, up to 40.
  case from35To40 = "35-40"
  /// from40To45 is 40 degrees, up to 45.
  case from40To45 = "40-45"
  /// from45 is 45 degrees and steeper.
  case from45 = "45+"

  /// id is the class as `geo/slope-ramp.json` spells it, `30-35`.
  public var id: String { rawValue }

  /// fromDegrees is the least slope of the class, in degrees.
  public var fromDegrees: Double {
    switch self {
    case .from25To30: 25
    case .from30To35: 30
    case .from35To40: 35
    case .from40To45: 40
    case .from45: 45
    }
  }
}
