/// SectionChipStat is one figure a section chip under a profile can state about its leg
/// (`geo.profile.section-chips`).
public enum SectionChipStat: String, CaseIterable, Sendable {
  /// distance is the leg's own length.
  case distance
  /// ascent is the meters the leg climbs.
  case ascent
  /// descent is the meters the leg loses.
  case descent
  /// grade is the leg's average grade, its climb less its loss over its length, in degrees.
  case grade
}
