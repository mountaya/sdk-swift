/// isMarkerLabelShown answers whether the label of the marker standing at `point`, `[x, y]` on a map
/// `mapWidth` wide and `mapHeight` tall, is drawn (`sdk/SPEC.md` §15): only where the point stands
/// on the map, its pin in view, from its left and top edges up to but not on its right and bottom
/// ones. A marker whose point is off the map, or names no place, shows no label, so a label is
/// never held at the map's edge without its pin, as `markerLabelPlacement` would hold it inside the
/// safe area.
package func isMarkerLabelShown(at point: [Double], mapWidth: Double, mapHeight: Double) -> Bool {
  guard point.count > 1 else { return false }
  // A comparison with a number that is not one is false, so a point that names no place fails.
  return point[0] >= 0 && point[0] < mapWidth && point[1] >= 0 && point[1] < mapHeight
}
