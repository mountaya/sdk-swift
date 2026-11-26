/// groundMeters is the distance covered on the ground to reach each vertex of a route's line, in
/// meters: the itinerary's distance axis read at the route's vertices, one distance per vertex,
/// ascending.
///
/// A flight charges every leg of its line, the leg that joins two lines included, since the camera
/// travels it. The ground charges nothing for the leg that reaches a jump, so the vertex a jump
/// lands on stands at the distance of the vertex it left. A route with no jump answers its
/// `cumulativeMeters(_:)`, and a jump at an index the line has no leg to, zero, under it or past
/// the line's last vertex, is no jump, nor is one named twice a second one.
///
/// It stays internal until the flight that reads a ground distance publishes it.
func groundMeters(_ route: RouteGeometry) -> [Double] {
  let cumulative = cumulativeMeters(route.line)
  let jumps = Set(route.jumps.filter { $0 >= 1 && $0 < cumulative.count })
  var ground: [Double] = []
  ground.reserveCapacity(cumulative.count)
  var jumped: Double = 0
  for index in cumulative.indices {
    if jumps.contains(index) { jumped += cumulative[index] - cumulative[index - 1] }
    ground.append(cumulative[index] - jumped)
  }
  return ground
}
