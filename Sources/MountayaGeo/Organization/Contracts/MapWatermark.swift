/// MapWatermark is the Mountaya watermark a map draws (`geo.organization.watermark`): the drawing
/// of the glyph table it is drawn from, where it stands, what it links to and the word it is
/// labelled by for assistive technology.
package struct MapWatermark: Sendable, Hashable {
  /// drawing is the name of the drawing in `GlyphDrawing.artwork`, `watermark`.
  package let drawing: String
  /// x and y are the frame's top-left corner from the top-left corner of the map's safe area, in
  /// logical pixels, and width and height its size, as tall as the drawing's box's proportion
  /// makes it.
  package let x: Double
  package let y: Double
  package let width: Double
  package let height: Double
  /// href is the address of Mountaya's site in the reader's language.
  package let href: String
  /// label is the path of the word the mark is labelled by, `watermark.label`.
  package let label: String
}
