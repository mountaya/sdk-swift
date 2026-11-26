/// RouteGeometry is the one route a fly-through follows: the line its camera flies, the ground's
/// elevation under each vertex where every vertex carries one, and the vertices it jumps to.
///
/// Two routes are the same route by what they hold, never by identity: every vertex, every
/// elevation and every jump, in order, each value the same number, `NaN` the same as `NaN` and 0
/// another than -0, as `geo.camera.route-content` states. A fresh copy is the same route and an
/// edited one is another, so a flight planned over one stands over the other exactly where the two
/// are equal. Equal routes hash alike, and a route stating no list is one stating an empty list.
public struct RouteGeometry: Sendable, Hashable {
  /// line is the vertices the camera flies through, in order, each `[longitude, latitude]` in
  /// degrees.
  public var line: [[Double]]
  /// elevations is the ground's elevation under each vertex of `line`, in meters, one per vertex;
  /// empty where the route states none, which is where some vertex carries none.
  public var elevations: [Double]
  /// jumps is the index in `line` of each vertex a jump lands on, ascending: the first vertex of
  /// each line after the first, which the camera flies to while the distance a reader is told
  /// charges nothing for the leg. Empty where the route states none.
  public var jumps: [Int]

  /// Creates a route from its line, and the elevations and the jumps it states, none by default.
  public init(line: [[Double]], elevations: [Double] = [], jumps: [Int] = []) {
    self.line = line
    self.elevations = elevations
    self.jumps = jumps
  }

  /// Two routes are equal where they hold the same vertices, elevations and jumps, in order, each
  /// value the same number.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.line.count == rhs.line.count
      && zip(lhs.line, rhs.line).allSatisfy { sameNumbers($0, $1) }
      && sameNumbers(lhs.elevations, rhs.elevations) && lhs.jumps == rhs.jumps
  }

  /// hash feeds every vertex, elevation and jump as the same-number relation reads it.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(line.count)
    for vertex in line {
      hasher.combine(sameNumbers: vertex)
    }
    hasher.combine(sameNumbers: elevations)
    hasher.combine(jumps)
  }
}
