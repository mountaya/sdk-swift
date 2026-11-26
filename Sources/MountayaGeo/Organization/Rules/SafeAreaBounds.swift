/// safeAreaBounds answers the safe area of a map `width` wide and `height` tall, the part of it the
/// device leaves visible, as a rectangle from the map's top-left corner (`sdk/SPEC.md` §15):
/// `safeArea` inside the map's edges, each inset no deeper than the map and none below zero, so a
/// safe area never leaves the map and is empty where the insets cover it whole. Every part of the
/// SDK's own interface keeps to it.
package func safeAreaBounds(_ safeArea: PixelPadding, width: Double, height: Double) -> ScreenRect {
  let width = max(width, 0)
  let height = max(height, 0)
  let left = min(max(safeArea.left, 0), width)
  let top = min(max(safeArea.top, 0), height)
  return ScreenRect(
    x: left, y: top, width: max(width - left - max(safeArea.right, 0), 0),
    height: max(height - top - max(safeArea.bottom, 0), 0))
}
