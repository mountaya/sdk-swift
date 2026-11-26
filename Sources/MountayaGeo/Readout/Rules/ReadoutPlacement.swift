/// readoutPlacement answers where a readout opened at `point`, `[x, y]` on the map, stands
/// (`map.readout.open`, `sdk/SPEC.md` §15): `readout-width` wide and `cardHeight` tall, its top-left
/// corner at the point, flipped to the left of the point where it would pass the right edge of
/// `bounds`, the map's safe area, and above it where it would pass its bottom edge, then moved back
/// inside a safe area too small for either. Where it would lay over the watermark's `frame`, it is
/// moved clear of it by the smallest move, `clearOfWatermark(_:frame:within:)`, and where no place
/// inside the safe area clears it, it opens with its top at the frame's bottom and the map's edge
/// cuts it. A point that names no place stands it at the safe area's top-left corner, kept clear
/// the same way. With no frame, the map drawing no mark, nothing moves it off the point.
package func readoutPlacement(
  at point: [Double], cardHeight: Double, within bounds: ScreenRect, clearOf frame: ScreenRect?
) -> ScreenRect {
  let width = ElementLayout.readoutWidth
  func held(_ value: Double, from low: Double, to high: Double) -> Double {
    min(max(value, low), max(high, low))
  }
  guard point.count > 1, point[0].isFinite, point[1].isFinite else {
    return clearOfWatermark(
      ScreenRect(x: bounds.x, y: bounds.y, width: width, height: cardHeight), frame: frame,
      within: bounds)
  }
  let x = point[0] + width > bounds.maxX ? point[0] - width : point[0]
  let y = point[1] + cardHeight > bounds.maxY ? point[1] - cardHeight : point[1]
  let placed = ScreenRect(
    x: held(x, from: bounds.x, to: bounds.maxX - width),
    y: held(y, from: bounds.y, to: bounds.maxY - cardHeight), width: width, height: cardHeight)
  return clearOfWatermark(placed, frame: frame, within: bounds)
}
