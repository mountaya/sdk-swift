import GateSupport

@testable import MountayaGeo

extension InternalRunners {
  /// cameraMaxBoundsRefusal answers whether a pan lock with the case's `edges`, `[west, south,
  /// east, north]`, is refused before it reaches a renderer. The class of the refusal is the map
  /// engine's, which the contract's ladder does not name, so the fixture expects whether the lock
  /// is refused, and the rule a map engine refuses through answers exactly that. The rule stays
  /// internal until that engine publishes it.
  static let cameraMaxBoundsRefusal = Runner(
    id: "geo.camera.max-bounds-refusal", table: .internal
  ) { _, fixtureCase in
    .value(.bool(refusesMaxBounds(try fixtureCase.input.numbers(at: "edges"))))
  }

  /// cameraGroundMeters answers the ground distance to each vertex of a route with the case's
  /// `line` and its `jumps`, none where the case states none.
  ///
  /// A route's jump is a vertex index, an `Int`, so a jump the fixture writes as no whole number,
  /// as `geo/route-ground-meters.json` writes one, cannot be built into a route at all: it is no jump by construction, which is
  /// what the rule answers for it, and the runner builds the route without it. Every whole jump,
  /// zero and past the line included, reaches the rule as written.
  static let cameraGroundMeters = Runner(id: "geo.camera.ground-meters", table: .internal) {
    _, fixtureCase in
    let input = fixtureCase.input
    let jumps = (input["jumps"] == nil ? [] : try input.numbers(at: "jumps"))
      .compactMap { Int(exactly: $0) }
    let route = RouteGeometry(line: try input.positions(at: "line"), jumps: jumps)
    return .value(.array(groundMeters(route).map { .number($0) }))
  }
}
