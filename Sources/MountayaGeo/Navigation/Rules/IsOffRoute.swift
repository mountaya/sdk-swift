import MountayaClient

/// offRouteMeters is the distance from the route past which a traveller is off it, in meters
/// (`geo.navigation.off-route`).
///
/// One number for every activity and every SDK, never a setting, so two apps following one route
/// agree on where a traveller left it. Fifty meters is about twice the error a phone's position
/// routinely carries under trees or between valley walls: far enough that the noise of an ordinary
/// position never reroutes a traveller, and near enough that a walker who takes a wrong fork at a
/// right angle is told within a minute.
public let offRouteMeters = 50.0

/// isOffRoute tells whether a traveller `meters` from the route, as `metersToRoute(_:lines:)`
/// measures it, is off it: past `offRouteMeters`, and on it at the threshold and within it. A
/// distance that is no number is past no threshold.
public func isOffRoute(_ meters: Double) -> Bool {
  meters > offRouteMeters
}

/// isOffRouteAt tells whether a traveller at `position` is off the route `lines` draw, measured as
/// `metersToRoute(_:lines:)` measures a point to a line: in the local plane on the mean sphere,
/// each segment kept in one piece the short way round the antimeridian. A route of one vertex has
/// no segment to be near, and is infinitely far, so a traveller is off it everywhere. A position's
/// reported accuracy, speed and heading are not read, so one position is judged the same wherever
/// it is judged.
///
/// It is the rule every engine reads a position by: `RouteFollowingEngine` answers it from the
/// distance its reading of the position measures in the same pass as the progress, which is the
/// distance `metersToRoute(_:lines:)` measures to the route's line.
public func isOffRouteAt(_ position: [Double], lines: [GeoJSONLineString]) -> Bool {
  isOffRoute(metersToRoute(position, lines: lines))
}
