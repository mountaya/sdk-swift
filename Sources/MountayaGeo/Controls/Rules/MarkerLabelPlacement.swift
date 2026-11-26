/// markerLabelOffset is how far past a marker's point its label starts, past the pin, in logical
/// pixels.
package let markerLabelOffset: Double = 18

/// markerLabelPlacement answers where the label of the marker standing at `point`, `[x, y]` on the
/// map, stands, the label `width` wide and `height` tall (`sdk/SPEC.md` §15), or nil where the
/// point names no place: `markerLabelOffset` past the point toward the end its text runs to, to
/// its right unless `isRightToLeft`, and centred on it from top to bottom; then held inside
/// `bounds`, the map's safe area, and moved clear of the watermark's `frame` by the smallest move,
/// `clearOfWatermark(_:frame:within:)`, as a readout is. Where no place inside the safe area clears
/// the frame, its top stands at the frame's bottom and the map's edge cuts it: the label is drawn
/// above the mark, as a map's popups are, and never over it. With no frame, the map drawing no
/// mark, nothing but the safe area moves it.
package func markerLabelPlacement(
  at point: [Double], width: Double, height: Double, isRightToLeft: Bool,
  within bounds: ScreenRect, clearOf frame: ScreenRect?
) -> ScreenRect? {
  guard point.count > 1, point[0].isFinite, point[1].isFinite else { return nil }
  func held(_ value: Double, from low: Double, to high: Double) -> Double {
    min(max(value, low), max(high, low))
  }
  let x = isRightToLeft ? point[0] - markerLabelOffset - width : point[0] + markerLabelOffset
  let placed = ScreenRect(
    x: held(x, from: bounds.x, to: bounds.maxX - width),
    y: held(point[1] - height / 2, from: bounds.y, to: bounds.maxY - height), width: width,
    height: height)
  return clearOfWatermark(placed, frame: frame, within: bounds)
}
