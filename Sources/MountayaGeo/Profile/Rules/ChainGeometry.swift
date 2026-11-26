import MountayaClient

/// chainGeometry is the one geometry a chain of legs is profiled as: a GeometryCollection of each
/// leg's geometry in the chain's order, a leg with none left out, nil where none carries one. The
/// chain is also the curve, so a profile handed legs draws the line they come from and its chips
/// can never describe a line they were not cut from (`sdk/SPEC.md` §7).
public func chainGeometry(_ legs: [ItineraryLeg]) -> GeoJSONGeometry? {
  let geometries = legs.compactMap(\.geometry)
  guard !geometries.isEmpty else { return nil }
  return .geometryCollection(GeoJSONGeometryCollection(geometries: geometries))
}
