/// CurvePin is one pass of a place pinned on a profile's curve (`geo.profile.curve-placement`): its
/// key, the place, where it stands on the axis and in the plot, and the curve's altitude under it,
/// read on the line between the two samples either side, so a pin stands on the stroke.
///
/// Two are equal where they hold the same key, written alike, the same place and the same numbers,
/// as every value of the geo layer compares.
public struct CurvePin: Sendable, Hashable {
  /// key is unique per pass: `id#pass`, counting the place's passes from zero.
  public var key: String
  /// place is the place pinned.
  public var place: ProfilePlace
  /// distance is the meters from the start of the itinerary.
  public var distance: Double
  /// x is how far across the plot the pin stands.
  public var x: Double
  /// y is how far down the plot the pin stands, the curve's height at its distance.
  public var y: Double
  /// altitude is the curve's altitude under the pin, in meters above sea level.
  public var altitude: Double

  /// Creates a pin from its key, its place, its distance, where it stands and its altitude.
  public init(
    key: String, place: ProfilePlace, distance: Double, x: Double, y: Double, altitude: Double
  ) {
    self.key = key
    self.place = place
    self.distance = distance
    self.x = x
    self.y = y
    self.altitude = altitude
  }

  /// Two pins are equal where every member is the same.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameText(lhs.key, rhs.key) && lhs.place == rhs.place && sameNumber(lhs.distance, rhs.distance)
      && sameNumber(lhs.x, rhs.x) && sameNumber(lhs.y, rhs.y)
      && sameNumber(lhs.altitude, rhs.altitude)
  }

  /// hash feeds every member, each number as the same-number relation reads it.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(key)
    hasher.combine(place)
    hasher.combine(sameNumber: distance)
    hasher.combine(sameNumber: x)
    hasher.combine(sameNumber: y)
    hasher.combine(sameNumber: altitude)
  }
}
