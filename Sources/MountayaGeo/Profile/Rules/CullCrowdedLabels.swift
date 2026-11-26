/// axisLabelGutter is the clear space a place name kept under a profile's distance axis keeps from
/// its neighbours, the `gutterPixels` `geo/profile-axis-label-culling.json` declares, in the boxes'
/// own unit: two names a hair apart read as glyphs and not as a row, since the eye cannot tell which
/// distance belongs to which name.
public let axisLabelGutter: Double = 8

/// cullCrowdedLabels is the keys of the place names under a profile's distance axis left undrawn,
/// in itinerary order (`geo.profile.axis-label-culling`).
///
/// The first and the last are always drawn: they are the itinerary's own two ends, where a reader
/// looks first, and on a loop whose start and finish share a meter the order the places are listed
/// in makes the first the start and the last the finish. Each name between them, read left to
/// right, is drawn only where its left edge stands at least `gutter` past the right edge of the last
/// name drawn and its right edge at least that far before the last name's left edge, so the walk
/// never paints itself into a collision at the far end. Every other is left out: its place is still
/// a pin on the curve, carrying its name. A key listed twice and left out twice is stated once.
public func cullCrowdedLabels(_ boxes: [AxisLabelBox], gutter: Double = axisLabelGutter)
  -> [String]
{
  guard boxes.count >= 3, let first = boxes.first, let last = boxes.last else { return [] }
  var hidden: [String] = []
  var keptRight = first.right
  for box in boxes.dropFirst().dropLast() {
    if box.left >= keptRight + gutter && box.right + gutter <= last.left {
      keptRight = box.right
      continue
    }
    if !hidden.contains(where: { sameText($0, box.key) }) {
      hidden.append(box.key)
    }
  }
  return hidden
}
