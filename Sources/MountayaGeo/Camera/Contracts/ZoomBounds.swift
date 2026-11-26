/// ZoomBounds is the zoom range a map's camera is held to, the least and the greatest zoom it may
/// take, as a renderer's minimum and maximum zoom take them.
///
/// Two are equal where they hold the same numbers, `NaN` the same as `NaN` and 0 another than -0,
/// as every value of the geo layer compares, and equal values hash alike.
public struct ZoomBounds: Sendable, Hashable {
  /// minZoom is the least zoom, the farthest the camera may pull out.
  public var minZoom: Double
  /// maxZoom is the greatest zoom, the closest the camera may come in.
  public var maxZoom: Double

  /// Creates a range from its least and its greatest zoom.
  public init(minZoom: Double, maxZoom: Double) {
    self.minZoom = minZoom
    self.maxZoom = maxZoom
  }

  /// Two ranges are equal where both their ends are the same numbers.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameNumber(lhs.minZoom, rhs.minZoom) && sameNumber(lhs.maxZoom, rhs.maxZoom)
  }

  /// hash feeds both ends as the same-number relation reads them.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(sameNumber: minZoom)
    hasher.combine(sameNumber: maxZoom)
  }
}
