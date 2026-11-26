/// StandingRefusals is the refusals of access that stand on a map, each by the source it came from,
/// and whether one naming no source stands (`map.events.access-standing`).
struct StandingRefusals: Sendable, Equatable {
  /// sources is the id of every source whose refusal stands, each once, in the order refused.
  var sources: [String] = []
  /// unsourced is whether a refusal naming no source stands: of a style, a sprite, a glyph or the
  /// layers manifest.
  var unsourced = false

  /// isEmpty tells whether no refusal stands.
  var isEmpty: Bool { sources.isEmpty && !unsourced }
}
