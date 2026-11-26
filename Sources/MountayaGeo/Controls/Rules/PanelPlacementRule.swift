/// panelGap is the room, in logical pixels, between a toggle and the panel it opens beside it.
package let panelGap: Double = 8

/// panelFillInset is the room, in logical pixels, a panel filling a narrow map keeps from the left
/// and right edges of the map's safe area.
package let panelFillInset: Double = 10

/// panelPlacement answers where the panel a toggle opens stands over a map, and how it lays out
/// there (`geo.panels.layout`, `sdk/SPEC.md` §7 and §15): `toggle` is where the toggle stands,
/// `bounds` the map's safe area, the part of the map the device leaves visible, both in the space
/// the panel is laid in, and `panelHeight` how tall the panel was last laid out, nil before it was.
///
/// The panel opens beside its toggle, toward the inside of the safe area, to the toggle's left
/// where the toggle stands in its right half and to its right otherwise, `panelGap` apart, its top
/// level with the toggle's; where the safe area is narrow it fills its width less `panelFillInset`
/// on each side. A toggle in the upper half lays its panel out from its own top, so the panel
/// reaches no lower than the safe area; one in the lower half, as an app's own panel control may
/// stand, lays it out as tall as the safe area holds and raises it so its bottom stays inside. It is
/// held inside the safe area, and where it would lay over the watermark's `frame`, it moves below the
/// frame and never to its right, as every SDK's panel does: its top stands at the frame's bottom and
/// it is laid out from there, its height held to the room left between there and the safe area's
/// bottom, so its sections scroll inside that room, and where the safe area holds no room under the
/// frame, the map's edge cuts it.
package func panelPlacement(
  beside toggle: ScreenRect, within bounds: ScreenRect, panelHeight: Double?,
  clearOf frame: ScreenRect?
) -> PanelPlacement {
  let upper = toggle.y + toggle.height / 2 <= bounds.y + bounds.height / 2
  var layout = panelLayout(
    mapWidth: bounds.width, mapHeight: bounds.height,
    topInset: upper ? max(toggle.y - bounds.y, 0) : 0)
  let width =
    layout.fill
    ? max(bounds.width - 2 * panelFillInset, 0) : layout.width ?? ElementLayout.panelWidth
  let wanted =
    layout.fill
    ? bounds.x + panelFillInset
    : toggle.x + toggle.width / 2 > bounds.x + bounds.width / 2
      ? toggle.x - panelGap - width : toggle.maxX + panelGap
  let x = min(max(wanted, bounds.x), max(bounds.maxX - width, bounds.x))
  var y = upper ? toggle.y : min(toggle.y, bounds.maxY - (panelHeight ?? 0))
  y = min(max(y, bounds.y), max(bounds.maxY, bounds.y))
  let shown = ScreenRect(x: x, y: y, width: width, height: max(panelHeight ?? 1, 1))
  let top = frame.map { shown.overlaps($0) ? $0.maxY : y } ?? y
  if top != y || upper {
    layout = panelLayout(
      mapWidth: bounds.width, mapHeight: bounds.height, topInset: max(top - bounds.y, 0))
  }
  return PanelPlacement(x: x, y: top, width: width, layout: layout)
}
