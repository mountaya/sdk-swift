import MountayaClient

/// SearchHighlight is what a map draws for the result a reader picked from a search, so the answer
/// stays on the map while the list is read (`map.search.result-highlight`), as picking the result
/// marks it (`geo.search.pick`): a place, a point of interest, or a way.
///
/// A position is `[longitude, latitude]` and a box `[west, south, east, north]`, as a search row's
/// payload holds them, a box across the antimeridian written with its west edge east of its east
/// one. One is drawn at a time, above everything else on the map, in the map's accent.
///
/// Two are equal where they are of one kind holding the same values, a list of numbers compared as
/// every list of the geo layer is, `NaN` the same as `NaN` and 0 another than -0, and a category by
/// its scalars.
public enum SearchHighlight: Sendable, Hashable {
  /// place is the point-of-interest pin carrying a point, at `point`: how a place is marked, and an
  /// itinerary's start and a zone's point, none of which has a category of its own.
  case place(point: [Double])
  /// poi is a point of interest's own pin, in its category's glyph and colour, at `point`, the pin
  /// the tiles draw it with; one whose category the table styles none of is marked as a place.
  case poi(point: [Double], category: DataSchema.POICategory?)
  /// way is a way's line, `coordinates`, with a dot at each of its two ends where it traces two
  /// positions or more, else its extent, `bounds`, washed and outlined dashed, else a pin at its
  /// `anchor`.
  case way(anchor: [Double], bounds: [Double]?, coordinates: [[Double]]?)

  /// Two highlights are equal where they are of one kind and hold the same values.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.place(let point), .place(let otherPoint)):
      return sameNumbers(point, otherPoint)
    case (.poi(let point, let category), .poi(let otherPoint, let otherCategory)):
      return sameNumbers(point, otherPoint) && sameText(category, otherCategory)
    case (
      .way(let anchor, let bounds, let coordinates),
      .way(let otherAnchor, let otherBounds, let otherCoordinates)
    ):
      return sameNumbers(anchor, otherAnchor) && sameBox(bounds, otherBounds)
        && samePositions(coordinates, otherCoordinates)
    default:
      return false
    }
  }

  /// hash feeds the kind and its values, each number as the same-number relation reads it.
  public func hash(into hasher: inout Hasher) {
    switch self {
    case .place(let point):
      hasher.combine(0)
      hasher.combine(sameNumbers: point)
    case .poi(let point, let category):
      hasher.combine(1)
      hasher.combine(sameNumbers: point)
      hasher.combine(category)
    case .way(let anchor, let bounds, let coordinates):
      hasher.combine(2)
      hasher.combine(sameNumbers: anchor)
      hasher.combine(sameBox: bounds)
      hasher.combine(samePositions: coordinates)
    }
  }
}
