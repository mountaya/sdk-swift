/// placeGlyph answers the glyph a place is marked with in `set`: its own `glyph` where the set
/// draws it, the fallback pin, `waypointFallbackGlyph`, where the set cannot draw it or the place
/// names none, and nil, nothing at all, where the set cannot draw the pin either
/// (`geo.icons.glyph-fallback`).
///
/// A host chooses the set, and a set may hold less than the vocabulary, a licensed one built before
/// an icon was added, so a place is still marked rather than left blank. An amenity's badge falls
/// back to words instead (`badgeFallback(_:on:)`), and a control's glyph to nothing.
public func placeGlyph(_ glyph: String?, in set: GlyphSet) -> String? {
  if let glyph, set.markup[glyph] != nil {
    return glyph
  }
  return set.markup[waypointFallbackGlyph] == nil ? nil : waypointFallbackGlyph
}
