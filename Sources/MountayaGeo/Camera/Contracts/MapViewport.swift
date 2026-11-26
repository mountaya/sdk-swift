/// MapViewport is where a map's camera opens: the position it is centred on and how far it is
/// zoomed.
///
/// Two viewports are equal where they hold the same numbers, `NaN` the same as `NaN` and 0 another
/// than -0, as every value of the geo layer compares, and equal values hash alike.
public struct MapViewport: Sendable, Hashable {
  /// center is the position the camera is centred on, `[longitude, latitude]` in degrees, as the
  /// wire orders a position.
  public var center: [Double]
  /// zoom is the zoom level, on the scale every map of this SDK reads: 0 shows the whole world.
  public var zoom: Double

  /// Creates a viewport from the position it is centred on and its zoom.
  public init(center: [Double], zoom: Double) {
    self.center = center
    self.zoom = zoom
  }

  /// Two viewports are equal where their centers and their zooms are the same numbers.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameNumbers(lhs.center, rhs.center) && sameNumber(lhs.zoom, rhs.zoom)
  }

  /// hash feeds the center and the zoom as the same-number relation reads them.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(sameNumbers: center)
    hasher.combine(sameNumber: zoom)
  }
}
