/// POIStyle is how a point of interest of one category is drawn (`geo.layers.poi-style`): the glyph
/// its pin carries, a name of the marker set (`GlyphSet.marker`), and the colour the pin is drawn
/// in. Several categories share a glyph, a pharmacy and a hospital the medical cross, each told
/// apart by its colour.
///
/// Two are equal where they name the same glyph and the same colour, each text by its scalars and
/// the opacity as the same number, and equal styles hash alike.
public struct POIStyle: Sendable, Hashable {
  /// glyph is the name of the glyph the pin carries.
  public var glyph: String
  /// color is the colour the pin is drawn in.
  public var color: HexColor

  /// Creates a style from the glyph a pin carries and the colour it is drawn in.
  public init(glyph: String, color: HexColor) {
    self.glyph = glyph
    self.color = color
  }

  /// Two styles are equal where their glyph and their colour are the same.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameText(lhs.glyph, rhs.glyph) && sameText(lhs.color.hex, rhs.color.hex)
      && sameNumber(lhs.color.opacity, rhs.color.opacity)
  }

  /// hash feeds the glyph and the colour, its opacity as the same-number relation reads it.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(glyph)
    hasher.combine(color.hex)
    hasher.combine(sameNumber: color.opacity)
  }
}
