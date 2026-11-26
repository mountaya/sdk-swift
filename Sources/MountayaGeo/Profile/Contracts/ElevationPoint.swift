/// ElevationPoint is one sample of an elevation series: how far along the itinerary it stands, the
/// ground's altitude there, where it is, and its place in the series.
///
/// Two are equal where they hold the same numbers, `NaN` the same as `NaN` and 0 another than -0,
/// as every value of the geo layer compares. Equal values hash alike.
public struct ElevationPoint: Sendable, Hashable {
  /// distance is the meters from the start of the itinerary, along the ground.
  public var distance: Double
  /// elevation is the meters above sea level.
  public var elevation: Double
  /// lngLat is where the sample stands, `[longitude, latitude]` in degrees, so a hover can place a
  /// marker.
  public var lngLat: [Double]
  /// index is the sample's place in its series, from 0, which a chart quantizes a pointer
  /// position to.
  public var index: Int

  /// Creates a sample from its distance, its altitude, its position and its place in the series.
  public init(distance: Double, elevation: Double, lngLat: [Double], index: Int) {
    self.distance = distance
    self.elevation = elevation
    self.lngLat = lngLat
    self.index = index
  }

  /// Two samples are equal where every number is the same number and the index is one.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameNumber(lhs.distance, rhs.distance) && sameNumber(lhs.elevation, rhs.elevation)
      && sameNumbers(lhs.lngLat, rhs.lngLat) && lhs.index == rhs.index
  }

  /// hash feeds every field as the same-number relation reads it.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(sameNumber: distance)
    hasher.combine(sameNumber: elevation)
    hasher.combine(sameNumbers: lngLat)
    hasher.combine(index)
  }
}
