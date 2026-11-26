/// ItineraryWaypointRow is one row of a waypoint table: a pass of a place, and the stretch that
/// reaches it from the row before (`geo.profile.waypoint-rows`). Its key is unique per row, so a
/// loop passing a place twice lists it twice.
///
/// Two are equal where they hold the same key, written alike, the same place and the same numbers,
/// as every value of the geo layer compares.
public struct ItineraryWaypointRow: ProfileSpan, Sendable, Hashable {
  /// key is unique per row: `id#pass`, counting the place's passes from zero.
  public var key: String
  /// place is the place the row lists, with its id, name, colour, glyph and details.
  public var place: ProfilePlace
  /// index is the row's place in the table, from zero.
  public var index: Int
  /// from is where the stretch reaching the place starts, where the row before stands, in meters.
  public var from: Double
  /// to is where the place stands, in meters.
  public var to: Double
  /// metrics is the row's figures.
  public var metrics: ItineraryWaypointRowMetrics

  /// Creates a row from its key, its place, its index, its stretch and its figures.
  public init(
    key: String, place: ProfilePlace, index: Int, from: Double, to: Double,
    metrics: ItineraryWaypointRowMetrics
  ) {
    self.key = key
    self.place = place
    self.index = index
    self.from = from
    self.to = to
    self.metrics = metrics
  }

  /// Two rows are equal where every member is the same.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameText(lhs.key, rhs.key) && lhs.place == rhs.place && lhs.index == rhs.index
      && sameNumber(lhs.from, rhs.from) && sameNumber(lhs.to, rhs.to) && lhs.metrics == rhs.metrics
  }

  /// hash feeds every member, each number as the same-number relation reads it.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(key)
    hasher.combine(place)
    hasher.combine(index)
    hasher.combine(sameNumber: from)
    hasher.combine(sameNumber: to)
    hasher.combine(metrics)
  }
}
