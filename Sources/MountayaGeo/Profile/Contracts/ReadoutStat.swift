/// ReadoutStat is one figure a profile's cursor readout can state (`geo.profile.cursor-readout`).
public enum ReadoutStat: String, CaseIterable, Sendable {
  /// distance is the sample's distance from the start of the itinerary.
  case distance
  /// elevation is the sample's altitude.
  case elevation
  /// ascent is the meters climbed from the start of the itinerary to the sample.
  case ascent
  /// descent is the meters lost from the start of the itinerary to the sample.
  case descent
}
