/// badgeFallback answers the text written in an amenity's badge where the installed set cannot
/// draw its glyph: the amenity's `name`, in the reader's language, in a table's cell, that name's
/// first letter in capitals in a profile's stack, and nil, nothing, beside a label of its own,
/// which says it already (`geo.icons.glyph-fallback`).
///
/// A badge stands for a service the itinerary carries, so a set with no `amenity-` glyphs never
/// leaves it empty. The first letter is the first character a reader sees, an extended grapheme
/// cluster, never the first scalar or code unit: a letter written with a combining accent keeps
/// its accent, and an emoji is never cut in half. It is written in capitals by Unicode's own case
/// mapping, which reads no locale, so `ß` is `SS` for every reader; a name with no character
/// answers the empty text.
public func badgeFallback(_ name: String, on surface: BadgeSurface) -> String? {
  switch surface {
  case .cell: name
  case .stack: name.first.map { String($0).uppercased() } ?? ""
  case .labelled: nil
  }
}
