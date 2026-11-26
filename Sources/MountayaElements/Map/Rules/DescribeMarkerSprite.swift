import MountayaGeo

/// markerSpritePx is the side of a marker sprite, in pixels.
let markerSpritePx: Double = 48

/// markerBorderPx is the width of the border around a marker sprite's disc, in pixels.
let markerBorderPx: Double = 3

/// markerWhite is the colour of a marker sprite's border and of its glyph.
let markerWhite = "#ffffff"

/// describeMarkerSprite answers what the marker sprite of `glyph` in `color` draws from `set`, or
/// nil where the set does not hold the glyph, which makes no sprite (`map.icons.marker-sprite`).
///
/// The image is 48 pixels square: a disc in the feature's colour, as given, of radius 21 under a
/// white border 3 pixels wide centred on its edge, which the image holds whole with a pixel and a
/// half to spare, and the glyph in white fitted to the 24-pixel square at its centre, half the
/// image, whatever the box the set draws in: one unit of a 48-unit box is half a pixel, of a
/// 16-unit box a pixel and a half.
/// The glyph is painted as its set paints it (`glyphPaint(_:in:)`). A glyph the set holds with no
/// shape still makes a sprite: the rule asks whether the set holds it, never what it draws.
func describeMarkerSprite(_ glyph: String, color: String, in set: GlyphSet) -> MarkerSprite? {
  guard set.markup[glyph] != nil else { return nil }
  let half = markerSpritePx / 2
  // The glyph's square is half the image, centred.
  let glyphPx = markerSpritePx / 2
  return MarkerSprite(
    size: markerSpritePx,
    disc: MarkerSprite.Disc(
      center: [half, half], radius: half - markerBorderPx, fill: color, borderColor: markerWhite,
      borderWidth: markerBorderPx),
    glyph: MarkerSprite.GlyphFit(
      offset: (markerSpritePx - glyphPx) / 2, scale: glyphPx / set.viewBox, color: markerWhite))
}
