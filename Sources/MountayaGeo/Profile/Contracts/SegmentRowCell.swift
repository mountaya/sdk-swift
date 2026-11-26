import MountayaClient

/// SegmentRowCell is what one cell of a segment row states (`geo.profile.segment-table-cells`), as
/// a model before any of it is written: meters and seconds, a loss stated positive as the wire
/// states it, and nil where the row has no figure.
public enum SegmentRowCell: Sendable, Hashable {
  /// segment is the leg's name.
  case segment(name: String)
  /// profile is the leg's stretch of the whole itinerary's sparkline, lit in `color`, the leg's,
  /// or nil for the table's own.
  case profile(lit: ProfileRange, color: String?)
  /// distance is the leg's own length over the running distance at its end.
  case distance(leg: Double?, total: Double?)
  /// elevation is the leg's climb and loss over the running climb at its end, the climb alone.
  case elevation(ascent: Double?, descent: Double?, totalAscent: Double?)
  /// altitude is the leg's band where both its ends are known, else the one end known, the floor
  /// first, as `single`.
  case altitude(band: AltitudeRange?, single: Double?)
  /// duration is the seconds the leg is expected to take.
  case duration(seconds: Double?)
  /// difficulty is the leg's difficulty as the itinerary writes it, never translated.
  case difficulty(text: RestSchema.TrailDifficultyType?)

  /// column is the column the cell stands in.
  public var column: SegmentTableColumn {
    switch self {
    case .segment: .segment
    case .profile: .profile
    case .distance: .distance
    case .elevation: .elevation
    case .altitude: .altitude
    case .duration: .duration
    case .difficulty: .difficulty
    }
  }

  /// Two cells are equal where they stand in one column stating the same, numbers by the
  /// same-number relation and texts by their scalars.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.segment(let a), .segment(let b)): sameText(a, b)
    case (.profile(let a, let c), .profile(let b, let d)): a == b && sameText(c, d)
    case (.distance(let a, let c), .distance(let b, let d)): sameNumber(a, b) && sameNumber(c, d)
    case (.elevation(let a, let c, let e), .elevation(let b, let d, let f)):
      sameNumber(a, b) && sameNumber(c, d) && sameNumber(e, f)
    case (.altitude(let a, let c), .altitude(let b, let d)): a == b && sameNumber(c, d)
    case (.duration(let a), .duration(let b)): sameNumber(a, b)
    case (.difficulty(let a), .difficulty(let b)): sameText(a, b)
    default: false
    }
  }

  /// hash feeds the column, then what the cell states.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(column)
    switch self {
    case .segment(let name): hasher.combine(name)
    case .profile(let lit, let color):
      hasher.combine(lit)
      hasher.combine(color)
    case .distance(let leg, let total):
      hasher.combine(sameNumber: leg)
      hasher.combine(sameNumber: total)
    case .elevation(let ascent, let descent, let totalAscent):
      hasher.combine(sameNumber: ascent)
      hasher.combine(sameNumber: descent)
      hasher.combine(sameNumber: totalAscent)
    case .altitude(let band, let single):
      hasher.combine(band)
      hasher.combine(sameNumber: single)
    case .duration(let seconds): hasher.combine(sameNumber: seconds)
    case .difficulty(let text): hasher.combine(text)
    }
  }
}
