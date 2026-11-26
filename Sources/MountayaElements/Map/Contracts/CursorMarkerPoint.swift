import MountayaGeo

/// CursorMarkerPoint is where an element's cursor stands and how its marker is drawn
/// (`map.profile.cursor-marker`): the id the marker is pinned under, the position of the sample
/// the cursor stands on, `[longitude, latitude]`, its colour, nil for the map's own accent, and its
/// glyph.
///
/// Two are equal where every text is written alike and the positions are the same numbers.
public struct CursorMarkerPoint: Sendable, Hashable {
  /// id is the id the marker is pinned under.
  public var id: String
  /// lngLat is where the cursor stands, `[longitude, latitude]`.
  public var lngLat: [Double]
  /// color is the pin's colour, nil for the map's own accent.
  public var color: String?
  /// glyph is the name of the glyph the pin carries.
  public var glyph: String

  /// Creates a point from the marker's id, where the cursor stands, and the pin's colour and glyph.
  public init(id: String, lngLat: [Double], color: String? = nil, glyph: String = cursorMarkerGlyph)
  {
    self.id = id
    self.lngLat = lngLat
    self.color = color
    self.glyph = glyph
  }

  /// Two points are equal where every member is the same.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameText(lhs.id, rhs.id) && sameNumbers(lhs.lngLat, rhs.lngLat)
      && sameText(lhs.color, rhs.color) && sameText(lhs.glyph, rhs.glyph)
  }

  /// hash feeds every member, the position as the same-number relation reads it.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    for number in lngLat {
      hasher.combine(number.isNaN ? Double.nan.bitPattern : number.bitPattern)
    }
    hasher.combine(color)
    hasher.combine(glyph)
  }
}
