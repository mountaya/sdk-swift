/// ScreenProjection is how an edit reads a position on the screen: the map's projection from a
/// position, `[longitude, latitude]`, to the point it is drawn at, `[x, y]` in the screen's
/// density-independent points, and back. A point is iOS's own unit of the screen, the one
/// `sdk-kotlin` reads as Android's `dp` and `sdk-typescript` as the web's CSS pixel, so the
/// magnet's 40 reaches as far under a finger on every screen, whatever its density.
///
/// An edit measures in pixels because its magnet reads alike at every zoom: zoomed in, the same
/// pixels span less ground, so the magnet narrows exactly where the editor is being precise. The
/// renderer's own projection is one, which `MapView` hands `MapEngine.placeWaypoint(at:through:)`
/// for each tap; a consumer drawing a map of their own hands their renderer's, and a test any pair
/// of functions. It is read on the main actor, at the moment a waypoint is placed.
public struct ScreenProjection: Sendable {
  /// point is where a position is drawn on the screen, `[x, y]` in density-independent points.
  public let point: @MainActor @Sendable ([Double]) -> [Double]
  /// position is the position drawn at a point of the screen, `[longitude, latitude]`.
  public let position: @MainActor @Sendable ([Double]) -> [Double]

  /// Creates a projection from a position to its point on the screen, `point`, and back,
  /// `position`.
  public init(
    point: @escaping @MainActor @Sendable ([Double]) -> [Double],
    position: @escaping @MainActor @Sendable ([Double]) -> [Double]
  ) {
    self.point = point
    self.position = position
  }
}
