import Foundation

/// WalkedLeg is one leg of the walked lines: its two ends, where it starts on the distance axis,
/// and its length.
struct WalkedLeg: Sendable, Hashable {
  let previous: [Double]
  let current: [Double]
  let start: Double
  let meters: Double
}

/// MarkerPass is one close pass of a line by a place: where its nearest point stands on the axis,
/// and how near.
struct MarkerPass: Sendable, Hashable {
  let distance: Double
  let meters: Double
}

/// walkLegs lists every leg of a geometry's lines, laid end to end on the distance axis an
/// elevation series is drawn against: distance accumulates within a line, and the jump to the next
/// line costs none and is no leg, since nothing travels it. A vertex that names no place ends no
/// leg: the leg runs from the vertex before it that names one to the next that does.
func walkLegs(_ lines: [[[Double]]]) -> [WalkedLeg] {
  var legs: [WalkedLeg] = []
  var distance: Double = 0
  for line in lines {
    var previous: [Double]?
    for current in line where namesPlace(current) {
      if let from = previous {
        let meters = haversineMeters(from: from, to: current)
        legs.append(WalkedLeg(previous: from, current: current, start: distance, meters: meters))
        distance += meters
      }
      previous = current
    }
  }
  return legs
}

/// markerPasses is each close pass of a line's legs by the place at `position`: each run of
/// consecutive legs that come within `proximityMeters` of it is one pass, at the nearest point of
/// the run, the first of two equally near, in itinerary order. A place the line never comes that
/// near has none, and so does one that names no place.
func markerPasses(_ legs: [WalkedLeg], position: [Double], proximityMeters: Double) -> [MarkerPass]
{
  var passes: [MarkerPass] = []
  var best: MarkerPass?
  for leg in legs {
    let approach = approachOf(leg, to: position)
    if approach.meters <= proximityMeters {
      if let held = best, !(approach.meters < held.meters) { continue }
      best = approach
      continue
    }
    if let held = best { passes.append(held) }
    best = nil
  }
  if let held = best { passes.append(held) }
  return passes
}

/// The closest approach of a leg to the place at `position`, measured in a local east and north
/// frame at the leg's start: a degree north is the mean sphere's, and a degree east that times the
/// cosine of the start's latitude. Each longitude is read as the short way from the leg's start, so
/// a place written a whole turn away, or across the antimeridian, measures the meters it stands
/// off. A leg of no length is measured from its start, and a coordinate the place does not write is
/// `NaN`, which no pass is ever near.
private func approachOf(_ leg: WalkedLeg, to position: [Double]) -> MarkerPass {
  let startLongitude = leg.previous[0]
  let startLatitude = leg.previous[1]
  let metersPerDegreeEast = cos(startLatitude * radiansPerDegree) * metersPerDegreeMeanSphere
  let legEast = longitudeDelta(from: startLongitude, to: leg.current[0]) * metersPerDegreeEast
  let legNorth = (leg.current[1] - startLatitude) * metersPerDegreeMeanSphere
  let placeLongitude = position.count > 0 ? position[0] : .nan
  let placeLatitude = position.count > 1 ? position[1] : .nan
  let placeEast = longitudeDelta(from: startLongitude, to: placeLongitude) * metersPerDegreeEast
  let placeNorth = (placeLatitude - startLatitude) * metersPerDegreeMeanSphere
  let lengthSquared = legEast * legEast + legNorth * legNorth
  let along =
    lengthSquared == 0
    ? 0
    : minimumNumber(
      1, maximumNumber(0, (placeEast * legEast + placeNorth * legNorth) / lengthSquared))
  return MarkerPass(
    distance: leg.start + leg.meters * along,
    meters: hypot(placeEast - legEast * along, placeNorth - legNorth * along))
}
