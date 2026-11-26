/// curveStops is the gradient a profile's curve is painted with from coloured stretches of the
/// itinerary (`geo.profile.curve-stops`), its stops in offset order, each a fraction of the plot's
/// width from 0 to 1.
///
/// The stretches are read in distance order, one of no length left out, and where two overlap the
/// earlier keeps the shared ground. Each is placed where `profileX(_:totalDistance:window:)` draws
/// its two ends, held to the frame, and painted between two stops of its colour at its two edges, so
/// every change of colour is a hard edge of two stops at one offset rather than a blend. Ground no
/// stretch covers is two stops of no colour, which a renderer paints in its own accent, and a
/// colour stated twice at one offset, two stretches of one colour meeting, is stated once.
///
/// It is empty, no gradient at all, where no stretch keeps a length in the frame: the signal to
/// paint the curve in one colour.
public func curveStops(
  _ stretches: [CurveColor], totalDistance: Double, window: ProfileRange? = nil
) -> [CurveStop] {
  var stops: [(offset: Double, color: String?)] = []
  var cursor: Double = 0
  for span in curveSpans(stretches) {
    let start = maximumNumber(
      profileX(span.from, totalDistance: totalDistance, window: window), cursor)
    let end = profileX(span.to, totalDistance: totalDistance, window: window)
    guard end > start else { continue }
    if start > cursor {
      stops.append((cursor, nil))
      stops.append((start, nil))
    }
    stops.append((start, span.color))
    stops.append((end, span.color))
    cursor = end
  }
  guard !stops.isEmpty else { return [] }
  if cursor < profileViewBox {
    stops.append((cursor, nil))
    stops.append((profileViewBox, nil))
  }
  var kept: [CurveStop] = []
  for (index, stop) in stops.enumerated() {
    if index > 0, sameText(stops[index - 1].color, stop.color),
      stops[index - 1].offset == stop.offset
    {
      continue
    }
    kept.append(CurveStop(offset: stop.offset / profileViewBox, color: stop.color))
  }
  return kept
}
