/// steepnessOverlaySlug is the slug of the overlay the steepness classes paint, the
/// `steepnessOverlaySlug` `geo/slope-ramp.json` declares.
public let steepnessOverlaySlug = "steepness"

/// classifySteepness is the steepness class a slope of `degrees` falls in: the last class whose
/// `fromDegrees` it reaches, so 30 degrees is `30-35` and 45 or more `45+`. Nil under 25 degrees,
/// where no class begins, and for a slope that is no number. A descent is read as written, so it
/// falls in none.
public func classifySteepness(_ degrees: Double) -> SteepnessClass? {
  SteepnessClass.allCases.last { degrees >= $0.fromDegrees }
}
