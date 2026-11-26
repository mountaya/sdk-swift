/// watermarkWidth is how wide the frame the Mountaya watermark stands in is, in logical pixels,
/// `watermark-width`, 180 (`geo.organization.watermark`, `sdk/SPEC.md` §15). With
/// `watermarkHeight` and `watermarkInset` it is the extent a host keeps its own interface clear of,
/// from the top-left corner of the map's safe area, as Trail's search box does.
public let watermarkWidth: Double = ElementLayout.watermarkWidth

/// watermarkHeight is how tall the frame is, in logical pixels: as tall as the proportion of the
/// drawing's box makes it at `watermarkWidth`, 180 × 58 / 138.
public let watermarkHeight: Double = {
  let box = GlyphDrawing.artwork[watermarkDrawing]?.viewBox ?? []
  return box.count == 4 && box[2] > 0 ? watermarkWidth * box[3] / box[2] : 0
}()

/// watermarkInset is where the frame's top-left corner stands from the top-left corner of the
/// map's safe area, on both axes, in logical pixels, `watermark-inset`, -4, so the empty margin the
/// drawing keeps round the mark falls outside the safe area.
public let watermarkInset: Double = ElementLayout.watermarkInset

/// watermarkClearance is how far below the top of the map's safe area the frame ends, in logical
/// pixels, `watermarkInset` and `watermarkHeight` together: a view of the host's laid at the top
/// of the safe area, across its left edge, starts at least this far down to stay clear of the mark.
public let watermarkClearance: Double = watermarkInset + watermarkHeight

/// watermarkFrame answers where `mark` stands on a map whose safe area, the part of the map the
/// device leaves visible, stands `safeArea` inside the map's edges (`geo.organization.watermark`,
/// `sdk/SPEC.md` §15): the mark's frame, which `watermarkOf` measures from the top-left corner of
/// the safe area, measured from the map's own top-left corner. A map drawn full bleed, under the
/// status bar, a notch or a display cutout, so draws its mark below and beside them, where it can be
/// seen.
package func watermarkFrame(_ mark: MapWatermark, safeArea: PixelPadding) -> ScreenRect {
  ScreenRect(
    x: max(safeArea.left, 0) + mark.x, y: max(safeArea.top, 0) + mark.y, width: mark.width,
    height: mark.height)
}

/// watermarkFrame answers the frame the mark stands in, or will once drawn, on a map whose safe area
/// stands `safeArea` inside the map's edges, measured from the map's own top-left corner
/// (`geo.organization.watermark`, `sdk/SPEC.md` §15): `watermarkWidth` wide and `watermarkHeight`
/// tall, its top-left corner `watermarkInset` from the safe area's on both axes, the frame of every
/// mark `watermarkOf` answers. It is what every part of the SDK's own interface keeps clear of while
/// `isWatermarkKeptClear` holds it, the mark drawn there or its read still waiting.
package func watermarkFrame(safeArea: PixelPadding) -> ScreenRect {
  ScreenRect(
    x: max(safeArea.left, 0) + watermarkInset, y: max(safeArea.top, 0) + watermarkInset,
    width: watermarkWidth, height: watermarkHeight)
}
