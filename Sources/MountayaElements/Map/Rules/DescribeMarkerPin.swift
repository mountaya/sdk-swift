import MountayaGeo

/// markerPinDiameter is a marker pin's diameter, its ring included, in points.
let markerPinDiameter = 28.0

/// markerPinRingWidth is the width of the white ring a marker pin is drawn inside, in points.
let markerPinRingWidth = 3.0

/// markerPinGlyphSize is the side of the square a marker pin's glyph is drawn in, in points.
let markerPinGlyphSize = 16.0

/// markerPinDotSize is the diameter of the dot a marker pin with no glyph shows, in points.
let markerPinDotSize = 8.0

/// markerPinMarkColor is the colour of a marker pin's ring and of what it carries at its centre.
let markerPinMarkColor = "#ffffff"

/// describeMarkerPin describes the pin a marker given no view of its own is drawn as
/// (`map.marker.pin`): a disc 28 points across in `color`, the map's accent where it is nil, ringed
/// in white 3 points wide, with its glyph `glyph` in white in a square of 16 at its centre, or a
/// white dot 8 across where it names no glyph or `set` cannot draw the one it names. It is the disc
/// the map's sprites are, so a marker reads as one of the map's own pins.
func describeMarkerPin(color: String?, glyph: String?, in set: GlyphSet) -> MarkerPin {
  let centre: MarkerPin.Centre =
    if let glyph, set.markup[glyph] != nil {
      .glyph(glyph, size: markerPinGlyphSize, color: markerPinMarkColor)
    } else {
      .dot(size: markerPinDotSize, color: markerPinMarkColor)
    }
  return MarkerPin(
    diameter: markerPinDiameter, fill: color, ringColor: markerPinMarkColor,
    ringWidth: markerPinRingWidth, centre: centre)
}
