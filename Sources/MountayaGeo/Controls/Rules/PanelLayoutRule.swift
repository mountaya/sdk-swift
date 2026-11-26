/// panelLayout answers how a panel the controls open, the layers, points-of-interest or
/// preferences panel, is laid out over a map `mapWidth` wide and `mapHeight` tall, its top
/// `topInset` below the map's (`geo.panels.layout`), every measure the tokens table's `layout`:
///
/// - it is `panel-width` wide, 340, and fills the width its corner leaves on a map no wider than
///   `panel-narrow-map-width`, 576;
/// - its height is capped at the map's less its top inset, and on that narrow map less
///   `panel-narrow-bottom-inset`, 16, more, the room the embed keeps under it there, and never
///   below 0;
/// - its layer cards' pictures are `panel-picture-height` tall, 52, and
///   `panel-picture-height-narrow`, 40, on that narrow map.
///
/// The inset follows the controls the panel opens beside, so it is the platform's own.
package func panelLayout(mapWidth: Double, mapHeight: Double, topInset: Double) -> PanelLayout {
  let narrow = mapWidth <= ElementLayout.panelNarrowMapWidth
  let room = mapHeight - topInset - (narrow ? ElementLayout.panelNarrowBottomInset : 0)
  return PanelLayout(
    width: narrow ? nil : ElementLayout.panelWidth, fill: narrow, maxHeight: max(room, 0),
    pictureHeight: narrow
      ? ElementLayout.panelPictureHeightNarrow : ElementLayout.panelPictureHeight)
}
