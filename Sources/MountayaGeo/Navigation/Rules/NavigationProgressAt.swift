/// navigationProgressAt reads where a traveller at `position` stands on the route they follow, and
/// how far and how long they have left, to the next maneuver and to the arrival
/// (`geo.navigation.progress`).
///
/// Every distance along the route is its great-circle measurement, the `cumulativeMeters(_:)` of
/// its line, and a step's own `distance` is never read, so the two remainders are lengths of one
/// line and the second is never shorter than the first. Each stretch of the line, from one vertex
/// to the next, is placed in the local plane on the mean sphere around the position, as a corridor
/// is measured, and the position is projected onto it, clamped to its ends; a vertex that names no
/// place ends no stretch, which runs from the vertex before it that names one to the next that
/// does, as every walk of a line reads it. Only a stretch that ends at or past `previous` is
/// considered, so the return leg of an out-and-back is not mistaken for the way out and a loop's
/// start stays its start until the traveller has come round. Of those, the nearest foot wins, and
/// of feet equally near, the one on the earliest stretch, so a traveller standing on a maneuver's
/// vertex is told that maneuver rather than the one after it. A foot at fraction t of the stretch
/// from vertex i to vertex j stands at `d[i] + t * (d[j] - d[i])`, and exactly at `d[j]` at its
/// far end, and progress never moves back: a foot behind `previous` stands at `previous`.
///
/// The current step is the one whose range holds the foot's stretch, its `fromIndex` at most i
/// and its `toIndex` greater than i, so a step of one vertex is never current, and the next
/// maneuver is the following step's, none after the last. A route with no stretch, one of a single
/// vertex, stands at 0, in its last step. A remainder's duration is the current step's duration
/// times the share of its measured length still ahead, none where it measures nothing, plus, to
/// the arrival, the whole duration of every later step, added in order, and it is nil where a step
/// it reads states none.
///
/// `route` is the route followed, as `followedRouteOf(_:)` answers it. `position` is the
/// traveller's `[longitude, latitude]`, in degrees; one that names no place has no foot to measure
/// from, and reads `NaN` for every figure it measures, standing in the step that holds the first
/// stretch ahead of `previous`. `previous` is the progress the last position read, in meters along
/// the route, 0 on a route just received; it is held within the route's length, and `NaN` reads as
/// 0.
public func navigationProgressAt(_ route: FollowedRoute, position: [Double], previous: Double)
  -> NavigationProgress
{
  readPosition(route, position: position, previous: previous, measuringRoute: false).progress
}

/// navigationReadingAt reads `position` on the route followed in one pass over its line, as the
/// machine reads every position: the progress `navigationProgressAt(_:position:previous:)`
/// answers, and the distance `metersToRoute(_:lines:)` measures from the position to the route's
/// line, which the off-route rule reads (`isOffRoute(_:)`).
///
/// Each stretch's foot is placed once and serves both minima: the nearest foot of every stretch is
/// the distance to the route, behind `previous` included, and the nearest of the stretches that
/// end at or past `previous` is the progress's, each kept by its own rule's comparison, so each
/// answers exactly what its own rule answers. No window is taken from `previous`: a route may come
/// back past the traveller at any distance ahead, a loop or an out-and-back, and the nearest foot
/// ahead wins wherever it stands, so every stretch is measured.
func navigationReadingAt(_ route: FollowedRoute, position: [Double], previous: Double)
  -> (progress: NavigationProgress, metersToRoute: Double)
{
  readPosition(route, position: position, previous: previous, measuringRoute: true)
}

/// readPosition is the one pass both readings share: the progress at `position`, and, where
/// `measuringRoute` asks for it, the distance to the route's line, `Double.infinity` otherwise and
/// for a position that names no place.
private func readPosition(
  _ route: FollowedRoute, position: [Double], previous: Double, measuringRoute: Bool
) -> (progress: NavigationProgress, metersToRoute: Double) {
  let placed = route.placed
  let steps = route.steps
  let measured = route.measured
  let total = measured.last ?? 0
  let behind: Double
  if previous.isNaN || previous < 0 {
    behind = 0
  } else if previous > total {
    behind = total
  } else {
    behind = previous
  }
  // A position written short is read as one at no number, so every figure it measures is `NaN`.
  let point = [position.count > 0 ? position[0] : .nan, position.count > 1 ? position[1] : .nan]
  let metersPerDegreeLongitude = metersPerDegreeLongitudeAt(point[1])

  var stretchStart = -1
  var stretchEnd = -1
  var nearest = Double.infinity
  var fraction = 0.0
  // The distance to the route, every stretch's nearest foot, as `metersToRoute(_:lines:)` keeps it.
  var nearestAnywhere = Double.infinity
  // The stretches run between consecutive vertices that name a place, read off the route's
  // flattened vertices, which skipped every vertex that names none once, as the route was followed.
  for end in placed.indices.indices.dropFirst() {
    let start = end - 1
    // A stretch already passed is never projected onto for the progress, and the distance to the
    // route measures it all the same.
    let isAhead = !(placed.meters[end] < behind)
    guard isAhead || measuringRoute else { continue }
    let foot = footAround(
      longitude: point[0], latitude: point[1], metersPerDegreeLongitude: metersPerDegreeLongitude,
      fromLongitude: placed.longitudes[start], fromLatitude: placed.latitudes[start],
      toLongitude: placed.longitudes[end], toLatitude: placed.latitudes[end])
    if foot.distance < nearestAnywhere {
      nearestAnywhere = foot.distance
    }
    // Strictly nearer, so of feet equally near the earliest stretch's stands.
    if isAhead, stretchStart < 0 || foot.distance < nearest {
      stretchStart = placed.indices[start]
      stretchEnd = placed.indices[end]
      nearest = foot.distance
      fraction = foot.fraction
    }
  }

  var along = 0.0
  if stretchStart >= 0 {
    let start = measured[stretchStart]
    let end = measured[stretchEnd]
    // A foot on a stretch's far end stands exactly where the next stretch starts, so a traveller
    // on a maneuver's vertex is told no distance to it, rather than a rounding of one.
    let foot = fraction == 1 ? end : start + fraction * (end - start)
    along = maximumNumber(foot, behind)
  }

  let step =
    steps.firstIndex { $0.fromIndex <= stretchStart && stretchStart < $0.toIndex }
    ?? steps.count - 1
  let current = steps.indices.contains(step) ? steps[step] : nil
  let stepStart =
    current.map { measured.indices.contains($0.fromIndex) ? measured[$0.fromIndex] : 0 } ?? 0
  let stepEnd =
    current.map { measured.indices.contains($0.toIndex) ? measured[$0.toIndex] : total } ?? total
  let toManeuverDistance = maximumNumber(0, stepEnd - along)
  let stepLength = stepEnd - stepStart
  let share = stepLength > 0 ? toManeuverDistance / stepLength : 0
  let toManeuverDuration = current?.duration.map { $0 * share }

  var toArrivalDuration = toManeuverDuration
  for later in steps.indices where later > step {
    if let held = toArrivalDuration, let duration = steps[later].duration {
      toArrivalDuration = held + duration
    } else {
      toArrivalDuration = nil
    }
  }

  let progress = NavigationProgress(
    along: along,
    step: step,
    next: step + 1 < steps.count ? step + 1 : nil,
    toManeuver: NavigationRemainder(distance: toManeuverDistance, duration: toManeuverDuration),
    toArrival: NavigationRemainder(
      distance: maximumNumber(0, total - along), duration: toArrivalDuration)
  )
  // A position that names no place is infinitely far from every route, as `metersToRoute` reads it.
  let metersToRoute = measuringRoute && namesPlace(point) ? nearestAnywhere : .infinity
  return (progress, metersToRoute)
}
