/// SegmentTableColumn is one column a segment table draws for itself
/// (`geo.profile.segment-table-cells`).
public enum SegmentTableColumn: String, CaseIterable, Sendable {
  /// segment is the leg's name.
  case segment
  /// profile is the whole itinerary's sparkline with the leg's own stretch lit.
  case profile
  /// distance is the leg's length over the running distance.
  case distance
  /// elevation is the leg's climb and loss over the running climb.
  case elevation
  /// altitude is the leg's altitude band.
  case altitude
  /// duration is the leg's expected duration.
  case duration
  /// difficulty is the leg's difficulty, as the itinerary writes it.
  case difficulty
}
