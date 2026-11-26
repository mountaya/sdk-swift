/// mapSafeArea answers how far inside a map's edges its safe area stands, the part of the map the
/// device leaves visible (`sdk/SPEC.md` §15): `map` is where the map stands and `visible` the part of
/// the window the device leaves visible, its status bar, a notch or display cutout and every window
/// inset the operating system reports left out, both in the window's coordinates. Each inset is
/// the depth the map reaches past that edge of the visible part, none where it stays inside it and
/// never more than the map is deep, so a map laid inside the visible part has no inset and one
/// drawn full bleed has the window's own.
package func mapSafeArea(_ map: ScreenRect, visible: ScreenRect) -> PixelPadding {
  func depth(_ value: Double, within extent: Double) -> Double {
    guard value.isFinite, extent.isFinite else { return 0 }
    return min(max(value, 0), max(extent, 0))
  }
  return PixelPadding(
    top: depth(visible.y - map.y, within: map.height),
    right: depth(map.maxX - visible.maxX, within: map.width),
    bottom: depth(map.maxY - visible.maxY, within: map.height),
    left: depth(visible.x - map.x, within: map.width))
}
