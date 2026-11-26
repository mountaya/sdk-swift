import MountayaClient
import MountayaGeo

/// MapMarker is a pin a map shows at a place, above everything it draws: its id, its position, its
/// color, the glyph it carries and the label a tap on it shows.
///
/// A marker is the map's own, never a layer of its style: it takes no rank, no base map's change
/// takes it off, and its label is shown as it is written, in no language the map relabels. It is
/// drawn as a pin, a disc in its color, the map's accent where it names none, ringed in white, with
/// its glyph in white at its centre, or a white dot where it names no glyph or the map's glyph set
/// cannot draw the one it names (`map.marker.pin`). A tap on it is told to `MapView`'s `onTap` with
/// its id.
///
/// Two are equal where every member is the same, a position by the same-number relation and a
/// text by its scalars, as every Geo value compares.
public struct MapMarker: Sendable, Equatable, Identifiable {
  /// id names the marker, which a command naming it finds it by, scalar for scalar.
  public var id: String
  /// position is where the marker stands, `[longitude, latitude]`, as the wire orders one.
  public var position: [Double]
  /// color is the pin's color, a CSS hexadecimal color, or nil for the map's accent.
  public var color: String?
  /// glyph is the name of the glyph the pin carries, of the map's glyph set, or nil for a dot.
  public var glyph: String?
  /// label is the text a tap on the marker shows beside it, or nil for none.
  public var label: String?

  /// Creates a marker named `id` standing at `position`, in `color`, carrying `glyph`, showing
  /// `label` when tapped.
  public init(
    id: String, position: [Double], color: String? = nil, glyph: String? = nil,
    label: String? = nil
  ) {
    self.id = id
    self.position = position
    self.color = color
    self.glyph = glyph
    self.label = label
  }

  /// Two markers are equal where every member is the same.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameText(lhs.id, rhs.id) && sameNumbers(lhs.position, rhs.position)
      && sameText(lhs.color, rhs.color) && sameText(lhs.glyph, rhs.glyph)
      && sameText(lhs.label, rhs.label)
  }
}
