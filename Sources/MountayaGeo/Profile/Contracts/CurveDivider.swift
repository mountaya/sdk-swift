/// CurveDivider is one pass of a place that divides an itinerary, named under its profile's
/// distance axis (`geo.profile.curve-placement`): its key, the place, where it stands on the axis
/// and across the plot, and how far down the plot the curve stands there, where a drop line from
/// its name ends, nil where the series has no sample.
///
/// Two are equal where they hold the same key, written alike, the same place and the same numbers,
/// as every value of the geo layer compares.
public struct CurveDivider: Sendable, Hashable {
  /// key is unique per pass: `id#pass`, counting the place's passes from zero.
  public var key: String
  /// place is the place named.
  public var place: ProfilePlace
  /// distance is the meters from the start of the itinerary.
  public var distance: Double
  /// x is how far across the plot the name stands.
  public var x: Double
  /// y is how far down the plot the curve stands at the divider's distance, nil with no sample.
  public var y: Double?

  /// Creates a divider from its key, its place, its distance and where it stands.
  public init(key: String, place: ProfilePlace, distance: Double, x: Double, y: Double?) {
    self.key = key
    self.place = place
    self.distance = distance
    self.x = x
    self.y = y
  }

  /// name is the name written under the axis, the place's, or empty for a place with none.
  public var name: String { place.name ?? "" }

  /// Two dividers are equal where every member is the same, or absent on both.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameText(lhs.key, rhs.key) && lhs.place == rhs.place && sameNumber(lhs.distance, rhs.distance)
      && sameNumber(lhs.x, rhs.x) && sameNumber(lhs.y, rhs.y)
  }

  /// hash feeds every member, each number as the same-number relation reads it.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(key)
    hasher.combine(place)
    hasher.combine(sameNumber: distance)
    hasher.combine(sameNumber: x)
    hasher.combine(sameNumber: y)
  }
}
