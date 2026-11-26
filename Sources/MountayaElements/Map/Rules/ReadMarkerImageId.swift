import MountayaGeo

/// poiIconPrefix is the namespace a point of interest's sprite id opens with, as the Tile API's
/// point-of-interest layers name one: `poi-icon-`, the glyph, a hyphen and the colour's six
/// hexadecimal digits.
let poiIconPrefix = "poi-icon-"

/// markerImagePrefixes are the namespaces of the image ids a map answers with a marker sprite: a
/// waypoint's, `section-icon-`, and a point of interest's, `poi-icon-`, both the API's own.
let markerImagePrefixes = [waypointIconPrefix, poiIconPrefix]

/// poiIconImageId is the id of the marker sprite of `glyph` on a disc of `color`, as a point of
/// interest's layer names one: `poi-icon-`, the glyph, a hyphen, then the colour with one leading
/// `#` dropped and its ASCII capitals written small, so `mountain` in `#5D4037` is
/// `poi-icon-mountain-5d4037`, which `readMarkerImageId(_:in:)` reads back. Every other scalar of
/// the colour is kept as written, so a colour that is no hexadecimal colour names a sprite the map
/// answers none for.
func poiIconImageId(glyph: String, color: String) -> String {
  let scalars = color.unicodeScalars
  let digits = scalars.first == "#" ? scalars.dropFirst() : scalars[...]
  let small = digits.map { scalar in
    ("A"..."Z").contains(scalar) ? Unicode.Scalar(scalar.value + 0x20) ?? scalar : scalar
  }
  return poiIconPrefix + glyph + "-" + String(String.UnicodeScalarView(small))
}

/// readMarkerImageId answers the marker sprite the image id `id` names, drawn from `set`, or nil
/// for an id that names none (`map.icons.missing-image`).
///
/// An id names one where it is one of `markerImagePrefixes` followed by a glyph name, a hyphen and
/// six hexadecimal digits in either case, and the set holds that glyph. The name is everything
/// before the hyphen the six digits follow, so a name of several words, `road-access-permit`, is
/// read whole, and holds no line terminator, as a pattern's `.` reads none. The colour is `#` and
/// the six digits as the id writes them. Any other id is left missing: one under no prefix, one
/// whose tail is no name, hyphen and six digits, and one naming a glyph the set does not hold,
/// which would draw a blank disc. The id is read scalar by scalar.
func readMarkerImageId(_ id: String, in set: GlyphSet) -> MarkerImage? {
  let scalars = Array(id.unicodeScalars)
  guard
    let prefix = markerImagePrefixes.first(where: { scalars.starts(with: $0.unicodeScalars) })
  else { return nil }
  let tail = scalars.dropFirst(prefix.unicodeScalars.count)
  // A glyph name of one scalar at least, a hyphen, and six hexadecimal digits.
  guard tail.count >= 8 else { return nil }
  let hex = tail.suffix(6)
  let glyphScalars = tail.dropLast(7)
  guard tail[tail.endIndex - 7] == "-", hex.allSatisfy(isHexDigit),
    !glyphScalars.contains(where: isLineTerminator)
  else { return nil }
  let glyph = String(String.UnicodeScalarView(glyphScalars))
  guard set.markup[glyph] != nil else { return nil }
  return MarkerImage(glyph: glyph, color: "#" + String(String.UnicodeScalarView(hex)))
}

/// Whether a scalar is a hexadecimal digit in either case: `0` to `9`, `a` to `f`, `A` to `F`.
private func isHexDigit(_ scalar: Unicode.Scalar) -> Bool {
  ("0"..."9").contains(scalar) || ("a"..."f").contains(scalar) || ("A"..."F").contains(scalar)
}

/// Whether a scalar ends a line as a pattern's `.` reads one: a line feed, a carriage return, or
/// the line or paragraph separator.
private func isLineTerminator(_ scalar: Unicode.Scalar) -> Bool {
  scalar == "\n" || scalar == "\r" || scalar == "\u{2028}" || scalar == "\u{2029}"
}
