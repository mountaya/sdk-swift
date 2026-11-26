import MountayaClient

/// WaypointRowCell is what one cell of a waypoint row states (`geo.profile.waypoint-table-cells`),
/// as a model before any of it is written: meters, a loss stated positive as the wire states it,
/// and nil where the row has no figure.
public enum WaypointRowCell: Sendable, Hashable {
  /// waypoint is the glyph the place is marked with, its own where the table's set draws it and
  /// `waypointFallbackGlyph` otherwise, and its name, nil for a place with none, which is listed
  /// under the `profile` word `unlabelledWaypoint`.
  case waypoint(glyph: String, name: String?)
  /// profile is the stretch reaching the place, lit on the whole itinerary's sparkline.
  case profile(lit: ProfileRange)
  /// distance is the running distance to the place.
  case distance(total: Double)
  /// elevation is the climb and loss since the previous place.
  case elevation(ascent: Double?, descent: Double?)
  /// altitude is the place's altitude.
  case altitude(Double?)
  /// amenities is the services the place offers, in the order it states them.
  case amenities([RestSchema.WaypointAmenity])
  /// cutoff is the place's cut-off as the caller's formatter writes it, nil with no formatter or no
  /// cut-off.
  case cutoff(moment: String?)
  /// properties is the place's fields, each written by its declared format.
  case properties([WaypointField])

  /// column is the column the cell stands in.
  public var column: WaypointTableColumn {
    switch self {
    case .waypoint: .waypoint
    case .profile: .profile
    case .distance: .distance
    case .elevation: .elevation
    case .altitude: .altitude
    case .amenities: .amenities
    case .cutoff: .cutoff
    case .properties: .properties
    }
  }

  /// Two cells are equal where they stand in one column stating the same, numbers by the
  /// same-number relation and texts by their scalars.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.waypoint(let a, let c), .waypoint(let b, let d)): sameText(a, b) && sameText(c, d)
    case (.profile(let a), .profile(let b)): a == b
    case (.distance(let a), .distance(let b)): sameNumber(a, b)
    case (.elevation(let a, let c), .elevation(let b, let d)): sameNumber(a, b) && sameNumber(c, d)
    case (.altitude(let a), .altitude(let b)): sameNumber(a, b)
    case (.amenities(let a), .amenities(let b)): sameText(a, b)
    case (.cutoff(let a), .cutoff(let b)): sameText(a, b)
    case (.properties(let a), .properties(let b)): a == b
    default: false
    }
  }

  /// hash feeds the column, then what the cell states.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(column)
    switch self {
    case .waypoint(let glyph, let name):
      hasher.combine(glyph)
      hasher.combine(name)
    case .profile(let lit): hasher.combine(lit)
    case .distance(let total): hasher.combine(sameNumber: total)
    case .elevation(let ascent, let descent):
      hasher.combine(sameNumber: ascent)
      hasher.combine(sameNumber: descent)
    case .altitude(let altitude): hasher.combine(sameNumber: altitude)
    case .amenities(let services): hasher.combine(services)
    case .cutoff(let moment): hasher.combine(moment)
    case .properties(let fields): hasher.combine(fields)
    }
  }
}
