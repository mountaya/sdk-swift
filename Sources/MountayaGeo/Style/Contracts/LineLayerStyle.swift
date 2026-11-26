import MountayaClient

/// LineLayerStyle is how a map's `line` layer draws, as MapLibre's style document writes it: its
/// `layout` and `paint` properties under their style names, `line-cap` and `line-color`. The
/// layer's id, its source, the source layer it draws and its filter are its caller's, so one style
/// draws in any layer that names them.
///
/// Two are equal where they hold the same properties, compared as Geo compares JSON, a number by
/// the same-number relation, a text by its scalars and an object's members in any order, and equal
/// styles hash alike.
public struct LineLayerStyle: Sendable, Hashable {
  /// layout is the layer's layout properties, by their style names.
  public var layout: [String: JSONValue]
  /// paint is the layer's paint properties, by their style names.
  public var paint: [String: JSONValue]

  /// Creates a line layer's style from its layout and paint properties.
  public init(layout: [String: JSONValue], paint: [String: JSONValue]) {
    self.layout = layout
    self.paint = paint
  }

  /// Two styles are equal where their layout and their paint hold the same properties.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameJson(lhs.layout, rhs.layout) && sameJson(lhs.paint, rhs.paint)
  }

  /// hash feeds the layout and the paint as Geo compares JSON.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(sameJson: layout)
    hasher.combine(sameJson: paint)
  }
}
