/// WaypointField is one field a place's author published, as a card and a waypoint table state it
/// (`geo.profile.waypoint-property-value`): its key, the label its author gave it, its value
/// written by the format its author declared, and the address a renderer may anchor it by, only
/// where it is declared a link and its value is a web address.
///
/// Two are equal where every text is written alike, or absent on both.
public struct WaypointField: Sendable, Hashable {
  /// key is the field's key, unique within its place.
  public var key: String
  /// label is the field's name as a reader reads it.
  public var label: String
  /// value is the field's value as `waypointPropertyValue(_:units:formatInstant:)` writes it.
  public var value: String
  /// href is the address a renderer anchors the field by, nil where it is no link.
  public var href: String?

  /// Creates a field from its key, its label, its written value and its address.
  public init(key: String, label: String, value: String, href: String? = nil) {
    self.key = key
    self.label = label
    self.value = value
    self.href = href
  }

  /// Two fields are equal where every text is written alike, or absent on both.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameText(lhs.key, rhs.key) && sameText(lhs.label, rhs.label) && sameText(lhs.value, rhs.value)
      && sameText(lhs.href, rhs.href)
  }

  /// hash feeds every text.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(key)
    hasher.combine(label)
    hasher.combine(value)
    hasher.combine(href)
  }
}
