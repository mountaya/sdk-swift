/// NavigationRoute is a route as its source answers it: the geometry to follow, its steps as an
/// adapter read them, and the route's own estimate of its duration.
///
/// A host's route source answers one, built from the Data API's `directions` or from a saved
/// itinerary's segment, its steps read by `readDirectionsSteps(_:coordinateCount:)` or
/// `readItineraryDirectionsSteps(_:coordinateCount:)`; an engine follows it as
/// `followedRouteOf(_:)` answers it.
///
/// Two are equal where every vertex, every step and the duration are, each figure as the same
/// number, `NaN` the same as `NaN` and 0 another than -0.
public struct NavigationRoute: Sendable, Hashable {
  /// line is the route's geometry, `[longitude, latitude]` vertices in degrees with an optional
  /// altitude, as GeoJSON writes a line: the index basis of its steps.
  public var line: [[Double]]
  /// steps is the route's steps, in travel order: empty where it has none or its list was
  /// refused.
  public var steps: [NavigationStep]
  /// duration is the route's own estimate of its duration in seconds, or nil where it states
  /// none.
  public var duration: Double?

  /// Creates a route from its geometry, and the steps and the duration it states, none by
  /// default.
  public init(line: [[Double]], steps: [NavigationStep] = [], duration: Double? = nil) {
    self.line = line
    self.steps = steps
    self.duration = duration
  }

  /// Two routes are equal where they hold the same vertices, steps and duration, each figure the
  /// same number.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.line.count == rhs.line.count && zip(lhs.line, rhs.line).allSatisfy { sameNumbers($0, $1) }
      && lhs.steps == rhs.steps && sameNumber(lhs.duration, rhs.duration)
  }

  /// hash feeds every vertex, step and the duration, each figure as the same-number relation reads
  /// it.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(line.count)
    for vertex in line {
      hasher.combine(sameNumbers: vertex)
    }
    hasher.combine(steps)
    hasher.combine(sameNumber: duration)
  }
}
