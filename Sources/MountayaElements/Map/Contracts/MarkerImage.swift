import MountayaGeo

/// MarkerImage is the marker sprite an image id names (`map.icons.missing-image`): the glyph it
/// carries and the colour of its disc.
///
/// Two are equal where both are written with the same scalars.
struct MarkerImage: Sendable, Equatable {
  /// glyph is the set's name for the glyph the sprite carries.
  let glyph: String
  /// color is the disc's colour: `#` and the id's six hexadecimal digits, in the case the id writes
  /// them.
  let color: String

  static func == (lhs: Self, rhs: Self) -> Bool {
    sameText(lhs.glyph, rhs.glyph) && sameText(lhs.color, rhs.color)
  }
}
