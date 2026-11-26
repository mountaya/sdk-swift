/// StatStripStat is one figure the stat strip over a profile can state (`geo.profile.stat-strip`).
public enum StatStripStat: String, CaseIterable, Sendable {
  /// distance is the itinerary's length, or the cursor's distance while a scrub stands.
  case distance
  /// duration is the seconds the itinerary is expected to take.
  case duration
  /// ascent is the meters the itinerary climbs.
  case ascent
  /// descent is the meters the itinerary loses.
  case descent
  /// elevation is the itinerary's highest altitude, or the cursor's while a scrub stands.
  case elevation
  /// grade is the itinerary's steepest grade, or the grade at the cursor while a scrub stands.
  case grade
  /// difficulty is the itinerary's hardest difficulty, as it writes it.
  case difficulty
}
