import MountayaGeo

/// MapTap is a tap on a map: the place tapped, the point of the view it was tapped at, and the
/// marker tapped, where it was one.
///
/// Two are equal where every member is the same, a number by the same-number relation and a text
/// by its scalars, as every Geo value compares.
public struct MapTap: Sendable, Equatable {
  /// position is the place tapped, `[longitude, latitude]`, its longitude within [-180, 180]
  /// whichever copy of the world the tap fell on.
  public let position: [Double]
  /// point is where the tap fell in the view, `[x, y]` in points from its top left corner.
  public let point: [Double]
  /// marker is the id of the marker tapped, or nil where the tap fell on the map itself.
  public let marker: String?

  /// Creates a tap on `position`, at `point` of the view, on the marker of id `marker` or none.
  public init(position: [Double], point: [Double], marker: String? = nil) {
    self.position = position
    self.point = point
    self.marker = marker
  }

  /// Two taps are equal where every member is the same.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameNumbers(lhs.position, rhs.position) && sameNumbers(lhs.point, rhs.point)
      && sameText(lhs.marker, rhs.marker)
  }
}
