/// climbOpenWindowKm is the run a climb's opening grade is measured over, the `openWindowKm`
/// `geo/climbs.json` declares: the grade from the last sample at least this far back.
public let climbOpenWindowKm = 0.3

/// climbOpenGradePercent is the grade over the open window at which a climb opens,
/// `openGradePercent`.
public let climbOpenGradePercent: Double = 3

/// climbCloseGradePercent is the grade under which a climb has levelled off, `closeGradePercent`:
/// lower than the opening grade, so a brief easing does not split one ascent in two.
public let climbCloseGradePercent: Double = 1

/// climbCloseWindowKm is how far the grade must stay under `climbCloseGradePercent` before a climb
/// closes at its summit, `closeWindowKm`.
public let climbCloseWindowKm = 0.5

/// minClimbLengthKm is the shortest climb kept, foot to summit, `minClimbLengthKm`: a badge on a
/// bump reads as noise.
public let minClimbLengthKm = 0.5

/// The meters in a kilometer.
private let metersPerKilometer: Double = 1_000

/// detectClimbs is the categorized climbs on a profile's samples, ascending by distance, in order
/// of their start.
///
/// A climb opens where the grade from the last sample at least `climbOpenWindowKm` back reaches
/// `climbOpenGradePercent`, its foot at that sample, and tracks its summit, the highest sample so
/// far. It closes once that grade has stayed under `climbCloseGradePercent` for
/// `climbCloseWindowKm`, or at the end of the series, and the span is cut at its summit, not at the
/// flat that followed. A span shorter than `minClimbLengthKm`, or one
/// `climbCategoryFor(lengthMeters:avgGradePercent:)` gives no category, is dropped.
///
/// Every window is read in kilometers as the samples carry them, the run a difference of two
/// distances, so 1.2 − 0.9, a hair under 0.3, is short of the open window.
public func detectClimbs(_ points: [RouteProfilePoint]) -> [Climb] {
  var climbs: [Climb] = []
  guard points.count >= 2 else { return climbs }
  var open: OpenClimb?
  var easingSinceKm: Double?
  for index in 1..<points.count {
    let point = points[index]
    guard let grade = rollingGradePercent(points, at: index) else { continue }
    guard var climb = open else {
      if grade >= climbOpenGradePercent {
        let foot = footOf(points, at: index)
        open = OpenClimb(
          startKm: foot.distanceKm, startElevation: foot.elevation, peakKm: point.distanceKm,
          peakElevation: point.elevation)
      }
      continue
    }
    if point.elevation > climb.peakElevation {
      climb.peakElevation = point.elevation
      climb.peakKm = point.distanceKm
      easingSinceKm = nil
    }
    open = climb
    if grade < climbCloseGradePercent {
      let since = easingSinceKm ?? point.distanceKm
      easingSinceKm = since
      if point.distanceKm - since >= climbCloseWindowKm {
        if let closed = climb.closedAtSummit() { climbs.append(closed) }
        open = nil
        easingSinceKm = nil
      }
    } else {
      easingSinceKm = nil
    }
  }
  if let closed = open?.closedAtSummit() { climbs.append(closed) }
  return climbs
}

/// A climb while it is open: its foot, and the summit it has reached so far.
private struct OpenClimb {
  let startKm: Double
  let startElevation: Double
  var peakKm: Double
  var peakElevation: Double

  /// The climb cut at its summit, or nil where it is too short or too easy to keep.
  func closedAtSummit() -> Climb? {
    let lengthKm = peakKm - startKm
    let lengthMeters = lengthKm * metersPerKilometer
    let rise = peakElevation - startElevation
    let ratio = lengthKm > 0 ? rise / lengthMeters : 0
    let avgGradePercent = convertProportion(ratio, from: .ratio, to: .percent)
    guard
      let category = climbCategoryFor(lengthMeters: lengthMeters, avgGradePercent: avgGradePercent),
      lengthKm >= minClimbLengthKm
    else { return nil }
    return Climb(
      startKm: startKm, endKm: peakKm, peakElevation: peakElevation,
      avgGradePercent: avgGradePercent, category: category)
  }
}

/// The grade, in percent, from the last sample at least `climbOpenWindowKm` before the sample at
/// `index` to it, or nil while the series has not covered a full window.
private func rollingGradePercent(_ points: [RouteProfilePoint], at index: Int) -> Double? {
  let end = points[index]
  for back in stride(from: index - 1, through: 0, by: -1) {
    let start = points[back]
    let runKm = end.distanceKm - start.distanceKm
    if runKm >= climbOpenWindowKm {
      return convertProportion(
        (end.elevation - start.elevation) / (runKm * metersPerKilometer), from: .ratio,
        to: .percent)
    }
  }
  return nil
}

/// The foot of a climb opening at the sample at `index`: the last sample at least the open window
/// back.
private func footOf(_ points: [RouteProfilePoint], at index: Int) -> RouteProfilePoint {
  let point = points[index]
  for back in stride(from: index - 1, through: 0, by: -1)
  where point.distanceKm - points[back].distanceKm >= climbOpenWindowKm {
    return points[back]
  }
  return point
}
