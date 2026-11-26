/// AspectCardinal is the eighth of the compass an aspect faces (`geo.terrain.aspect-cardinal`),
/// each spelled as the contract spells it, `N` to `NW`, the key its word takes under
/// `readout.aspects`.
///
/// The cases are declared clockwise from north, the order `allCases` yields.
public enum AspectCardinal: String, Sendable, Hashable, CaseIterable {
  /// north faces the 45 degrees centred on 0.
  case north = "N"
  /// northEast faces the 45 degrees centred on 45.
  case northEast = "NE"
  /// east faces the 45 degrees centred on 90.
  case east = "E"
  /// southEast faces the 45 degrees centred on 135.
  case southEast = "SE"
  /// south faces the 45 degrees centred on 180.
  case south = "S"
  /// southWest faces the 45 degrees centred on 225.
  case southWest = "SW"
  /// west faces the 45 degrees centred on 270.
  case west = "W"
  /// northWest faces the 45 degrees centred on 315.
  case northWest = "NW"
}
