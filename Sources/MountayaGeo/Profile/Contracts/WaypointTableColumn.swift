/// WaypointTableColumn is one column a waypoint table draws for itself
/// (`geo.profile.waypoint-table-cells`).
public enum WaypointTableColumn: String, CaseIterable, Sendable {
  /// waypoint is the place's glyph and name.
  case waypoint
  /// profile is the whole itinerary's sparkline with the stretch reaching the place lit.
  case profile
  /// distance is the running distance to the place.
  case distance
  /// elevation is the climb and loss since the previous place.
  case elevation
  /// altitude is the place's altitude.
  case altitude
  /// amenities is the services the place offers.
  case amenities
  /// cutoff is the place's cut-off, as the caller's formatter writes it.
  case cutoff
  /// properties is the fields the place's author published.
  case properties
}
