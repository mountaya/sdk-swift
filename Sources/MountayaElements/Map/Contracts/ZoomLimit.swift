import MountayaGeo

/// ZoomLimit is one end of a zoom window a call states (`map.camera.zoom-window`): kept as the map
/// holds it, released back to the renderer's own, its floor for the least zoom and its default
/// ceiling for the greatest, or moved to a zoom.
///
/// A zoom is written as a number, `map.setZoomBounds(min: 8, max: 12)`, and a limit left out is
/// kept.
public enum ZoomLimit: Sendable, Equatable, ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
  /// kept leaves the limit where the map holds it.
  case kept
  /// released moves the limit back to the renderer's own: the floor under which it draws nothing,
  /// or the ceiling it builds a map with.
  case released
  /// zoom moves the limit to a zoom, a finite number.
  case zoom(Double)

  /// Creates the limit at a zoom written as a fractional number.
  public init(floatLiteral value: Double) {
    self = .zoom(value)
  }

  /// Creates the limit at a zoom written as a whole number.
  public init(integerLiteral value: Int) {
    self = .zoom(Double(value))
  }

  /// Two limits are equal where they are of one kind, a zoom as the same number.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.kept, .kept), (.released, .released): true
    case (.zoom(let a), .zoom(let b)): sameNumber(a, b)
    default: false
    }
  }
}
