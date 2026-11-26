import MountayaGeo

/// CursorMarkerPin is what the marker an element added for its cursor is drawn with
/// (`map.profile.cursor-marker`): its colour, nil for the map's own accent, and its glyph. An
/// element holds it while its marker stands, and nil where it added none, so it never takes down a
/// marker it did not add.
///
/// Two are equal where both are written alike, or the colour absent on both.
public struct CursorMarkerPin: Sendable, Hashable {
  /// color is the pin's colour, nil for the map's own accent.
  public var color: String?
  /// glyph is the name of the glyph the pin carries.
  public var glyph: String

  /// Creates what a cursor marker is drawn with.
  public init(color: String?, glyph: String) {
    self.color = color
    self.glyph = glyph
  }

  /// Two pins are equal where both are written alike.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameText(lhs.color, rhs.color) && sameText(lhs.glyph, rhs.glyph)
  }

  /// hash feeds the colour, then the glyph.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(color)
    hasher.combine(glyph)
  }
}
