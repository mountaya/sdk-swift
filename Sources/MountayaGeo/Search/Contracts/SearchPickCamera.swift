/// SearchPickCamera is how a map's camera moves onto a picked search result (`geo.search.pick`): it
/// frames an extent, or it flies to a point at a zoom.
///
/// A box is `[west, south, east, north]`, written as the result states it, its west edge east of its
/// east one where it crosses the antimeridian, and a position `[longitude, latitude]`. Two are equal
/// where they are of one kind holding the same numbers, `NaN` the same as `NaN` and 0 another than
/// -0.
public enum SearchPickCamera: Sendable, Hashable {
  /// fit frames `bounds` whole (`geo.camera.fit`).
  case fit(bounds: [Double])
  /// fly flies to `center` at `zoom`.
  case fly(center: [Double], zoom: Double)

  /// Two moves are equal where they are of one kind and hold the same numbers.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.fit(let bounds), .fit(let otherBounds)):
      return sameNumbers(bounds, otherBounds)
    case (.fly(let center, let zoom), .fly(let otherCenter, let otherZoom)):
      return sameNumbers(center, otherCenter) && sameNumber(zoom, otherZoom)
    default:
      return false
    }
  }

  /// hash feeds the kind and its numbers as the same-number relation reads them.
  public func hash(into hasher: inout Hasher) {
    switch self {
    case .fit(let bounds):
      hasher.combine(0)
      hasher.combine(sameNumbers: bounds)
    case .fly(let center, let zoom):
      hasher.combine(1)
      hasher.combine(sameNumbers: center)
      hasher.combine(sameNumber: zoom)
    }
  }
}
