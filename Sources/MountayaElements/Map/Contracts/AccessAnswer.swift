/// AccessAnswer is what a map hears that a refusal of access stands or ends on
/// (`map.events.access-standing`).
enum AccessAnswer: Sendable, Equatable {
  /// refused is a request refused access, from the source named, or from none: a style, a sprite,
  /// a glyph or the layers manifest.
  case refused(source: String?)
  /// tile is a tile of the source named loading.
  case tile(source: String)
  /// style is a style loading.
  case style
}
