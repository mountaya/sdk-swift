/// FollowedRoute is a route as a traveller follows it: its geometry, and the steps that cover it
/// once, in travel order, which are the route's own or, for a route with none, a departure and an
/// arrival (`geo.navigation.stepless-route`).
///
/// It is built by `followedRouteOf(_:)` alone, so its steps always tile its line and hold one step
/// at the least, which every reading of a position along it relies on, and its line is measured
/// once, when it is followed, rather than at every position read along it. Two are equal where
/// every vertex and every step are, each figure as the same number, `NaN` the same as `NaN` and 0
/// another than -0. A route and its copies share one storage, which is compared first, so a state
/// that holds the route it held compares no vertex.
public struct FollowedRoute: Sendable, Hashable {
  /// Storage is what a route and its copies share: the line, the steps, the line's measure, and the
  /// vertices that name a place, flattened once. It is Sendable: every stored property is a
  /// constant of a Sendable type.
  private final class Storage: Sendable {
    let line: [[Double]]
    let steps: [NavigationStep]
    let measured: [Double]
    let placed: Placed

    init(line: [[Double]], steps: [NavigationStep], measured: [Double]) {
      self.line = line
      self.steps = steps
      self.measured = measured
      placed = Placed(line: line, measured: measured)
    }
  }

  /// Placed is the vertices of a route's line that name a place, in order, flattened once, when
  /// the route is followed: each one's index in the line, its longitude, its latitude, and its
  /// distance along the line, read off the line's measure. A reading along the route walks these
  /// four arrays of numbers, never the line's array of arrays, which hands each vertex over as an
  /// array of its own to be retained and released, and a vertex that names no place is skipped
  /// once, here, as every walk of a line skips it.
  struct Placed: Sendable {
    let indices: [Int]
    let longitudes: [Double]
    let latitudes: [Double]
    let meters: [Double]

    /// Creates the placed vertices of `line`, measured by `measured`, its `cumulativeMeters(_:)`.
    init(line: [[Double]], measured: [Double]) {
      var indices: [Int] = []
      var longitudes: [Double] = []
      var latitudes: [Double] = []
      var meters: [Double] = []
      indices.reserveCapacity(line.count)
      longitudes.reserveCapacity(line.count)
      latitudes.reserveCapacity(line.count)
      meters.reserveCapacity(line.count)
      for (index, vertex) in line.enumerated() where namesPlace(vertex) {
        indices.append(index)
        longitudes.append(vertex[0])
        latitudes.append(vertex[1])
        meters.append(measured[index])
      }
      self.indices = indices
      self.longitudes = longitudes
      self.latitudes = latitudes
      self.meters = meters
    }
  }

  private let storage: Storage

  /// Creates the route a traveller follows over `line` by `steps`, which tile it, measuring the
  /// line once.
  init(line: [[Double]], steps: [NavigationStep]) {
    self.init(line: line, steps: steps, measured: cumulativeMeters(line))
  }

  /// Creates the route a traveller follows over `line` by `steps`, which tile it, standing on
  /// `measured`, the line's `cumulativeMeters(_:)` already read, so the line is measured no
  /// second time.
  init(line: [[Double]], steps: [NavigationStep], measured: [Double]) {
    storage = Storage(line: line, steps: steps, measured: measured)
  }

  /// line is the route's geometry, as its source answered it: the index basis of its steps.
  public var line: [[Double]] { storage.line }

  /// steps is the steps followed, in travel order, covering the geometry once.
  public var steps: [NavigationStep] { storage.steps }

  /// measured is the distance along `line` to each of its vertices, its `cumulativeMeters(_:)`,
  /// measured once, when the route is followed, and shared by its copies: the measure every
  /// reading of a position along it stands on, and a guidance plan reads a step's length from.
  public var measured: [Double] { storage.measured }

  /// placed is the route's vertices that name a place, flattened once, when the route is followed.
  var placed: Placed { storage.placed }

  /// Two routes are equal where they share one storage, or hold the same vertices and steps, each
  /// figure the same number.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    if lhs.storage === rhs.storage { return true }
    return lhs.line.count == rhs.line.count
      && zip(lhs.line, rhs.line).allSatisfy { sameNumbers($0, $1) } && lhs.steps == rhs.steps
  }

  /// hash feeds every vertex and step, each figure as the same-number relation reads it.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(line.count)
    for vertex in line {
      hasher.combine(sameNumbers: vertex)
    }
    hasher.combine(steps)
  }
}
