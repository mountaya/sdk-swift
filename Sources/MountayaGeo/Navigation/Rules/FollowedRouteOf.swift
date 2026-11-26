import MountayaClient

/// followedRouteOf answers the route a traveller follows: a route's geometry, and the steps that
/// tile it (`geo.navigation.stepless-route`).
///
/// A route whose steps tile its geometry is followed by them, unchanged. One with none, a
/// `linestring` segment's or one whose list was refused, is followed as two steps in the same
/// vocabulary: a `depart` from vertex 0 to the last, carrying the route's own duration, none where
/// it states none, and the geometry's great-circle length as `routeLengthMeters(_:)` measures it,
/// a vertex that names no place bridged, then a `goal` on the last vertex, of no distance and no
/// duration. Neither names a way or an exit, so both are said in their `Plain` form. Steps that do
/// not tile the geometry are refused as `readDirectionsSteps(_:coordinateCount:)` refuses them,
/// and the route is followed as one with none.
///
/// The geometry is measured once, the departure's length read off the measure the route then
/// holds, so following a route costs one measurement of its line and no more.
///
/// It answers nil for a geometry with no vertex, which is no route to follow.
public func followedRouteOf(_ route: NavigationRoute) -> FollowedRoute? {
  let line = route.line
  let last = line.count - 1
  if last < 0 { return nil }
  let measured = cumulativeMeters(line)
  if stepsTile(route.steps, coordinateCount: line.count) {
    return FollowedRoute(line: line, steps: route.steps, measured: measured)
  }
  let departure = NavigationStep(
    fromIndex: 0, toIndex: last, maneuver: .depart,
    distance: measured.last ?? 0, duration: route.duration)
  let arrival = NavigationStep(
    fromIndex: last, toIndex: last, maneuver: .goal, distance: 0, duration: 0)
  return FollowedRoute(line: line, steps: [departure, arrival], measured: measured)
}
