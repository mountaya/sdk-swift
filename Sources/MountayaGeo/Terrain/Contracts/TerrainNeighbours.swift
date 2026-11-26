/// TerrainNeighbours is the elevation of the ground one spacing to each side of a point, in
/// meters: north and south along its meridian, east and west along its parallel.
///
/// Two are equal where they hold the same numbers, `NaN` the same as `NaN` and 0 another than -0,
/// as every value of the geo layer compares, and equal values hash alike.
public struct TerrainNeighbours: Sendable, Hashable {
  /// north is the elevation one spacing to the north, in meters.
  public var north: Double
  /// south is the elevation one spacing to the south, in meters.
  public var south: Double
  /// east is the elevation one spacing to the east, in meters.
  public var east: Double
  /// west is the elevation one spacing to the west, in meters.
  public var west: Double

  /// Creates the four elevations around a point, each named by its side.
  public init(north: Double, south: Double, east: Double, west: Double) {
    self.north = north
    self.south = south
    self.east = east
    self.west = west
  }

  /// Two neighbourhoods are equal where every elevation is the same number.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameNumber(lhs.north, rhs.north) && sameNumber(lhs.south, rhs.south)
      && sameNumber(lhs.east, rhs.east) && sameNumber(lhs.west, rhs.west)
  }

  /// hash feeds each elevation as the same-number relation reads it.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(sameNumber: north)
    hasher.combine(sameNumber: south)
    hasher.combine(sameNumber: east)
    hasher.combine(sameNumber: west)
  }
}
