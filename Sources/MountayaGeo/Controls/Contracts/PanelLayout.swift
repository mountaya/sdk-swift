/// PanelLayout is how a panel the controls open is laid out over a map (`geo.panels.layout`): its
/// width, nil where it fills the width its corner leaves, whether it fills it, the most it may be
/// tall, and how tall its layer cards' pictures are, each in logical pixels.
package struct PanelLayout: Sendable, Hashable {
  /// width is the panel's width, nil where it fills the width its corner leaves.
  package let width: Double?
  /// fill is whether the panel fills the width its corner leaves, on a narrow map.
  package let fill: Bool
  /// maxHeight is the most the panel is tall, its body scrolling under its title row past it.
  package let maxHeight: Double
  /// pictureHeight is how tall a layer card's picture is.
  package let pictureHeight: Double
}
